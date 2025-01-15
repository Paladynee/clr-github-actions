defmodule Clr.Block do
  @moduledoc false

  alias Clr.Air.Function
  alias Clr.Air.Instruction
  alias Clr.Function

  @enforce_keys ~w[function args_meta reqs]a
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
  @type slot :: Clr.slot()

  @type t :: %__MODULE__{
          function: term,
          args_meta: [Clr.meta()],
          reqs: [Clr.meta()],
          return: nil | {Clr.type(), meta :: keyword},
          loc: nil | loc,
          stack: [{loc, term}],
          awaits: %{optional(slot) => reference},
          slots: %{optional(slot) => slot_spec}
        }

  @spec new(Function.t(), [Clr.type()]) :: t
  def new(function, args_meta) do
    # fill requirements with an empty set for each argument.
    reqs = Enum.map(args_meta, fn _ -> %{} end)
    %__MODULE__{function: function.name, args_meta: args_meta, reqs: reqs}
  end

  @spec analyze(t, Clr.Air.codeblock()) :: t
  def analyze(block, code) do
    code
    |> Enum.reduce(block, &analyze_instruction/2)
    |> flush_awaits
    |> then(&Map.replace!(&1, :reqs, transfer_requirements(&1.reqs, &1)))
  end

  defp transfer_requirements(reqs, block) do
    reqs
    |> Enum.with_index()
    |> Enum.map(fn {req, slot} ->
      case fetch_up!(block, slot) do
        {{_type, meta}, _} ->
          Map.merge(req, meta)
      end
    end)
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

  def put_reqs(block, arg, reqs) do
    %{block | reqs: List.update_at(block.reqs, arg, &Enum.into(reqs, &1))}
  end

  def put_return(block, type, meta \\ %{}) do
    %{block | return: {type, meta}}
  end

  # used to fetch the type and update the block type.  If the
  def fetch_up!(block, slot) do
    case Map.fetch(block.slots, slot) do
      {:ok, typemeta} ->
        {typemeta, block}

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

  @spec flush_awaits(t) :: t
  def flush_awaits(block) do
    Enum.reduce(block.awaits, %{block | awaits: %{}}, fn
      {slot, future}, block ->
        case Function.await(future) do
          {:ok, {type, lambda}} ->
            block
            |> put_type(slot, type)
            |> then(lambda)

          {:error, {exception, stacktrace}} ->
            reraise exception, stacktrace
        end
    end)
  end

  @type call_meta_adder_fn :: (Block.t(), [Clr.slot() | nil] -> Block.t())
  @spec call_meta_adder(t) :: call_meta_adder_fn
  # this function produces a lambda that can be used to add metadata to
  # slots in a block, generated from the requirements of the "called" block.
  def call_meta_adder(%{reqs: reqs}) do
    fn caller_fn, slots ->
      slots
      |> Enum.zip(reqs)
      |> Enum.reduce(caller_fn, fn {slot, req_list}, caller_fn ->
        if slot, do: put_meta(caller_fn, slot, req_list), else: caller_fn
      end)
    end
  end
end
