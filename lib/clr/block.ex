defmodule Clr.Block do
  @moduledoc false

  alias Clr.Air.Function
  alias Clr.Air.Instruction
  alias Clr.Function
  alias Clr.Type

  @enforce_keys ~w[function args reqs]a
  defstruct @enforce_keys ++
              [
                :loc,
                :return,
                ptr: %{},
                stack: [],
                awaits: %{},
                slots: %{}
              ]

  @type loc :: {row :: non_neg_integer, col :: non_neg_integer}
  @type slot_spec :: {Clr.type(), meta :: keyword}
  @type slot :: Clr.slot()

  @type t :: %__MODULE__{
          function: term,
          args: [Clr.type()],
          reqs: [Clr.meta()],
          loc: nil | loc,
          return: nil | Clr.type(),
          ptr: %{optional(slot) => slot},
          stack: [{loc, term}],
          awaits: %{optional(slot) => reference},
          slots: %{optional(slot) => slot_spec}
        }

  @spec new(Function.t(), [Clr.type()], Clr.type()) :: t
  def new(function, args, return) do
    # fill requirements with an empty set for each argument.
    reqs = Enum.map(args, fn _ -> %{} end)
    %__MODULE__{function: function.name, args: args, reqs: reqs, return: return}
  end

  @spec analyze(t, Clr.Air.codeblock()) :: t
  def analyze(block, code) do
    mapper = Clr.get_instruction_mapper()

    code
    |> Enum.sort()
    |> Enum.reduce(block, &analyze_instruction(&1, &2, mapper))
    |> flush_awaits
    |> then(&Map.replace!(&1, :reqs, transfer_requirements(&1.reqs, &1)))
  end

  defp transfer_requirements(reqs, block) do
    reqs
    |> Enum.with_index()
    |> Enum.map(fn {req, slot} ->
      case fetch_up!(block, slot) do
        {type, _} ->
          case Type.get_meta(type) do
            %{deleted: info} ->
              Map.put(req, :transferred, info)

            _ ->
              req
          end
      end
    end)
  end

  # instructions that are always subject to analysis.
  # generally, any control flow instruction or dbg_stmt instruction must be
  # analyzed.

  defp analyze_instruction({{slot, mode}, %module{} = instruction}, block, mapper) do
    # {slot, instruction, block.function, block.slots} |> dbg(limit: 25)
    block =
      case Instruction.slot_type(instruction, slot, block) do
        {:future, block} -> block
        {type, block} -> put_type(block, slot, type)
      end

    case {mode, is_map_key(mapper, module)} do
      {:keep, true} ->
        modulespecs = Map.fetch!(mapper, module)

        Enum.reduce_while(modulespecs, block, fn {_, checker}, acc ->
          checker.analyze(instruction, slot, acc, %{})
        end)

      {:clobber, true} ->
        modulespecs = Map.fetch!(mapper, module)

        Enum.reduce_while(modulespecs, block, fn
          {:always, checker}, acc ->
            checker.analyze(instruction, slot, acc, %{})

          _, acc ->
            acc
        end)

      {_, false} ->
        block
    end
  end

  defp analyze_instruction(_, block, _), do: block

  def put_type(block, slot, type) do
    %{block | slots: Map.put(block.slots, slot, type)}
  end

  def put_type(block, slot, type, meta) do
    %{block | slots: Map.put(block.slots, slot, Type.put_meta(type, meta))}
  end

  def put_meta(block, slot, meta) do
    %{block | slots: Map.update!(block.slots, slot, &Type.put_meta(&1, meta))}
  end

  def put_await(block, slot, reference) do
    %{block | awaits: Map.put(block.awaits, slot, reference)}
  end

  def put_reqs(block, arg, reqs) do
    %{block | reqs: List.update_at(block.reqs, arg, &Enum.into(reqs, &1))}
  end

  def put_ref(block, pointed_slot, pointer_slot) do
    %{block | ptr: Map.put(block.ptr, pointed_slot, pointer_slot)}
  end

  def put_return(block, type), do: %{block | return: type}

  def get_meta(block, slot) do
    block.slots
    |> Map.fetch!(slot)
    |> Type.get_meta()
  end

  # used to fetch the type and update the block type.  If it's a future,
  # await the future.
  def fetch_up!(block, slot) do
    case Map.fetch(block.slots, slot) do
      {:ok, typemeta} ->
        {typemeta, block}

      :error ->
        await_future(block, slot)
    end
  end

  # fetches the type without updating the block.  Should only be used if the
  # type is known to not be a future
  def fetch!(block, slot), do: Map.fetch!(block.slots, slot)

  # fetches the typemeta without updating the block.  Should only be used
  # if the type is known not to be a future, and the type is known to not
  # be noreturn or void.
  def fetch_meta!(block, slot), do: Type.get_meta(fetch!(block, slot))

  # update the type of a slot using a modifier function.  Check to see
  # if the block has recorded that any pointers point to this slot.  If
  # so, chase the pointer and update the type inside the slot which points
  # to this slot.
  def update_type!(block, slot, fun) do
    chase_pointer(block, slot, 0, fun)
  end

  defp chase_pointer(block, slot, depth, fun) do
    new_block = if chase = block.ptr[slot] do
      chase_pointer(block, chase, depth + 1, fun)
    else
      block
    end

    new_block
    |> fetch!(slot)
    |> deep_update(depth, fun)
    |> then(&put_type(new_block, slot, &1))
  end

  defp deep_update(type, 0, fun), do: fun.(type)

  defp deep_update({:ptr, :one, child, ptr_meta}, depth, fun) do
    {:ptr, :one, deep_update(child, depth - 1, fun), ptr_meta}
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

      {:error, exception} when is_exception(exception) ->
        raise exception

      {:error, {exception, stacktrace}} when is_exception(exception) ->
        reraise exception, stacktrace
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
