defmodule Clr.Block do
  @moduledoc false

  alias Clr.Air.Function
  alias Clr.Air.Instruction
  alias Clr.Function

  @enforce_keys ~w[function args reqs]a
  defstruct @enforce_keys ++
              [
                :loc,
                :return,
                stack: [],
                awaits: %{},
                slots: %{}
              ]

  @type loc :: {row :: non_neg_integer, col :: non_neg_integer}
  @type slot_spec :: {Clr.type(), meta :: keyword}
  @type slot :: Clr.Air.slot()

  @type t :: %__MODULE__{
          function: term,
          args: [Clr.type()],
          reqs: [keyword],
          return: nil | {Clr.term(), meta :: keyword},
          loc: nil | loc,
          stack: [{loc, term}],
          awaits: %{optional(slot) => reference},
          slots: %{optional(slot) => slot_spec}
        }

  @spec new(Function.t(), [Clr.type()]) :: t
  def new(function, args) do
    # fill requirements with an empty set for each argument.
    reqs = Enum.map(args, fn _ -> [] end)
    %__MODULE__{function: function.name, args: args, reqs: reqs}
  end

  @spec analyze(t, Clr.Air.code()) :: t
  def analyze(block, code) do
    Enum.reduce(code, block, &analyze_instruction/2)
  end

  # instructions that are always subject to analysis.
  # generally, any control flow instruction or dbg_stmt instruction must be
  # analyzed.

  @always [
    Clr.Air.Instruction.RetSafe,
    Clr.Air.Instruction.StoreSafe,
    Clr.Air.Instruction.DbgStmt,
    Clr.Air.Instruction.Call
  ]

  # if we have a "keep" instruction or a required instruction, subject the
  # instruction to analysis.
  defp analyze_instruction({{slot, mode}, %always{} = instruction}, block)
       when always in @always or mode == :keep do
    Instruction.analyze(instruction, slot, block)
  end

  # clobbered instructions can be safely ignored.
  defp analyze_instruction({{_, :clobber}, _}, state), do: state

  # general block operations

  def put_type(block, line, type, meta \\ []) do
    meta = Map.new(meta)
    %{block | slots: Map.put(block.slots, line, {type, meta})}
  end

  def put_meta(block, line, meta) do
    %{
      block
      | slots:
          Map.update!(block.slots, line, fn {type, old_meta} ->
            {type, Enum.into(meta, old_meta)}
          end)
    }
  end

  def put_await(block, line, reference) do
    %{block | awaits: Map.put(block.awaits, line, reference)}
  end

  # used to fetch the type and update the block type.  If the
  def fetch_up!(block, slot) do
    case Map.fetch(block.slots, slot) do
      {:ok, typemeta} -> {typemeta, block}
      :error -> 
        await_future(block, slot)
    end
  end

  defp await_future(block, slot) do
    block.awaits
    |> Map.fetch!(slot)
    |> Function.await()
    |> case do
      {:ok, {type, lambda}} when is_function(lambda, 1) ->
        block
        |> put_type(slot, type)
        |> then(lambda)
        |> fetch_up!(slot)
      {:error, exception} -> 
        raise exception
    end
  end
end
