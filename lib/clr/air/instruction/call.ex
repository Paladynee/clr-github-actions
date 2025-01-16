defmodule Clr.Air.Instruction.Call do
  use Clr.Air.Instruction

  defstruct [:fn, :args]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lvalue fn_literal literal cs slotref lparen rparen lbrack rbrack]a)

  Pegasus.parser_from_string(
    """
    call <- 'call' lparen (fn_literal / slotref) cs lbrack (argument (cs argument)*)? rbrack rparen
    argument <- slotref / literal / lvalue
    """,
    call: [export: true, post_traverse: :call]
  )

  def call(rest, args, context, _, _) do
    case Enum.reverse(args) do
      ["call", fun | args] ->
        {rest, [%__MODULE__{fn: fun, args: args}], context}
    end
  end

  alias Clr.Block
  alias Clr.Function
  alias Clr.Type
  import Clr.Air.Lvalue

  def analyze(call, slot, block) do
    case call.fn do
      {:literal, {:fn, [~l"mem.Allocator" | params], type, _fn_opts}, {:function, function}} ->
        process_allocator(function, params, type, call.args, slot, block)

      {:literal, _type, {:function, function_name}} ->
        # we also need the context of the current function.

        {metas_slots, block} =
          Enum.map_reduce(call.args, block, fn
            {:literal, _type, _}, block ->
              {{%{}, nil}, block}

            {slot, _}, block ->
              {type, block} = Block.fetch_up!(block, slot)
              {{Type.get_meta(type), slot}, block}
          end)

        {args_meta, slots} = Enum.unzip(metas_slots)

        block.function
        |> merge_name(function_name)
        |> Function.evaluate(args_meta, slots)
        |> case do
          {:future, ref} ->
            Block.put_await(block, slot, ref)

          {:ok, result} ->
            Block.put_type(block, slot, result)
        end
    end
  end

  defp process_allocator(
         "create" <> _,
         [],
         {:errorable, e, {:ptr, _, _, _} = ptr_type},
         [{:literal, ~l"mem.Allocator", struct}],
         slot,
         analysis
       ) do
    type =
      ptr_type
      |> Type.from_air()
      |> Type.put_meta(heap: Map.fetch!(struct, "vtable"))
      |> then(&{:errorable, e, &1, %{}})

    Block.put_type(analysis, slot, type)
  end

  defp process_allocator(
         "destroy" <> _,
         [_],
         ~l"void",
         [{:literal, ~l"mem.Allocator", struct}, {src, _}],
         slot,
         block
       ) do
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

      {{:ptr, :one, _type, %{heap: ^vtable}}, block} ->
        block
        # for now.
        |> Block.put_meta(src, deleted: this_function)
        |> Block.put_type(slot, Type.void())

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

  # utility functions

  defp merge_name({:lvalue, lvalue}, function_name) do
    {:lvalue, List.replace_at(lvalue, -1, function_name)}
  end
end
