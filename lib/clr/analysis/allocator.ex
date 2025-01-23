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

  @impl true
  def analyze(call, _slot, metablock, config) do
    case call.fn do
      {:literal, {:fn, [~l"mem.Allocator" | _], type, _fn_opts}, {:function, "create_" <> _}} ->
        process_create(type, call.args, metablock, config)

      {:literal, {:fn, [~l"mem.Allocator" | _], _, _fn_opts}, {:function, "destroy" <> _}} ->
        process_destroy(call.args, metablock, config)

      _ ->
        {:cont, metablock}
    end
  end

  defp process_create(
         {:errorable, e, {:ptr, :one, type, _}},
         [{:literal, ~l"mem.Allocator", struct}],
         {meta, block},
         _config
       ) do
    heapinfo = %{vtable: Map.fetch!(struct, "vtable"), function: block.function, loc: block.loc}

    # probably need a better "metas" system, but for now this will have to do.
    
    type =
      type
      |> Type.from_air()
      |> Type.put_meta(undefined: Undefined.meta(block))
      |> then(&{:ptr, :one, &1, %{heap: heapinfo}})
      |> Type.put_meta(meta)
      |> then(&{:errorable, e, &1, %{}})

    # prevent further analysis on this function.
    {:halt, {type, block}}
  end

  defp process_destroy([{:literal, ~l"mem.Allocator", struct}, {src, _}], {meta, block}, _config) do
    vtable = Map.fetch!(struct, "vtable")
    this_function = block.function

    raise "aap"

    # TODO: consider only flushing the awaits that the function needs.
    # block
    # |> Block.flush_awaits()
    # |> Block.fetch_up!(src)
    # |> case do
    #  {{:ptr, :one, _type, %{deleted: prev_function}}, block} ->
    #    raise Clr.DoubleFreeError,
    #      previous: Clr.Air.Lvalue.as_string(prev_function),
    #      deletion: Clr.Air.Lvalue.as_string(this_function),
    #      loc: block.loc
    #
    #  {{:ptr, :one, _type, %{heap: ^vtable}}, block} ->
    #    block
    #    |> Block.put_meta(src, deleted: this_function)
    #    |> Block.put_type(slot, Type.void())
    #
    #  {{:ptr, :one, _type, %{heap: other}}, block} ->
    #    raise Clr.AllocatorMismatchError,
    #      original: Clr.Air.Lvalue.as_string(other),
    #      attempted: Clr.Air.Lvalue.as_string(vtable),
    #      function: Clr.Air.Lvalue.as_string(this_function),
    #      loc: block.loc
    #
    #  _ ->
    #    raise Clr.AllocatorMismatchError,
    #      original: :stack,
    #      attempted: Clr.Air.Lvalue.as_string(vtable),
    #      function: Clr.Air.Lvalue.as_string(this_function),
    #      loc: block.loc
    # end
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
