use Protoss

defprotocol Clr.Analysis.Allocator do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, block, config)
after
  defstruct []

  alias Clr.Air.Instruction.Function.Call

  @impl true
  def always, do: [Call]

  @impl true
  def when_kept, do: []
end

defimpl Clr.Analysis.Allocator, for: Clr.Air.Instruction.Function.Call do
  alias Clr.Type

  import Clr.Air.Lvalue

  alias Clr.Analysis.Undefined
  alias Clr.Block

  @impl true
  def analyze(call, slot, block, config) do
    case call.fn do
      {:literal, {:fn, [~l"mem.Allocator" | _], _, _fn_opts}, {:function, "create_" <> _}} ->
        process_create(call.args, slot, block, config)

      {:literal, {:fn, [~l"mem.Allocator" | _], _, _fn_opts}, {:function, "destroy" <> _}} ->
        process_destroy(call.args, slot, block, config)

      _ ->
        {:cont, block}
    end
  end

  defp process_create(
         [{:literal, ~l"mem.Allocator", struct}],
         slot,
         block,
         _config
       ) do
    heapinfo = %{vtable: Map.fetch!(struct, "vtable"), function: block.function, loc: block.loc}

    block =
      Block.update_type!(block, slot, fn
        {:errorable, e, {:ptr, :one, type, ptr_meta}, err_meta} ->
          {:errorable, e,
           {:ptr, :one, Type.put_meta(type, undefined: Undefined.meta(block)),
            Map.put(ptr_meta, :heap, heapinfo)}, err_meta}
      end)

    {:halt, block}
  end

  defp process_destroy([{:literal, ~l"mem.Allocator", struct}, {src, _}], slot, block, _config) do
    vtable = Map.fetch!(struct, "vtable")
    this_function = block.function

    # TODO: consider only flushing the awaits that the function needs.
    block
    |> Block.flush_awaits()
    |> Block.fetch_up!(src)
    |> case do
      {{:ptr, :one, _type, %{deleted: prev_function}}, block} ->
        raise Clr.DoubleFreeError,
          previous: Clr.Air.Lvalue.as_string(prev_function),
          deletion: Clr.Air.Lvalue.as_string(this_function),
          loc: block.loc

      {{:ptr, :one, _type, %{heap: %{vtable: ^vtable}}}, block} ->
        deleted_info = %{function: this_function, loc: block.loc}
        {Type.void(), Block.put_meta(block, src, deleted: deleted_info)}

      {{:ptr, :one, _type, %{heap: other}}, block} ->
        raise Clr.AllocatorMismatchError,
          original: Clr.Air.Lvalue.as_string(other),
          attempted: Clr.Air.Lvalue.as_string(vtable),
          function: Clr.Air.Lvalue.as_string(this_function),
          loc: block.loc

      _ ->
        raise Clr.AllocatorMismatchError,
          original: :stack,
          attempted: Clr.Air.Lvalue.as_string(vtable),
          function: Clr.Air.Lvalue.as_string(this_function),
          loc: block.loc
    end
  end
end

#
# defp process_allocator(
#  "destroy" <> _,
#  [_],
#  ~l"void",
#  [{:literal, ~l"mem.Allocator", struct}, {src, _}],
#  slot,
#  block
# ) do
# vtable = Map.fetch!(struct, "vtable")

# end

# utility functions
