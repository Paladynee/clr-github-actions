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
              {{_type, meta}, block} = Block.fetch_up!(block, slot)
              {{meta, slot}, block}
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
         {:errorable, e, {:ptr, count, type, opts}},
         [{:literal, ~l"mem.Allocator", struct}],
         slot,
         analysis
       ) do
    heap_type =
      {:errorable, e, {:ptr, count, type, Keyword.put(opts, :heap, Map.fetch!(struct, "vtable"))}}

    Block.put_type(analysis, slot, heap_type)
  end

  defp process_allocator(
         "destroy" <> _,
         [_],
         ~l"void",
         [{:literal, ~l"mem.Allocator", struct}, {src, _}],
         slot,
         analysis
       ) do
    # Function.process_awaited(analysis)

    {{:ptr, :one, type, opts}, analysis} = Block.fetch!(analysis, src)
    vtable = Map.fetch!(struct, "vtable")

    case Keyword.fetch(opts, :heap) do
      {:ok, ^vtable} ->
        analysis
        |> Block.put_type(src, {:ptr, :one, type, Keyword.put(opts, :heap, :deleted)})
        |> Block.put_type(slot, ~l"void")
        |> maybe_mark_transferred(opts)

      {:ok, :deleted} ->
        raise Clr.DoubleFreeError,
          function: Clr.Air.Lvalue.as_string(analysis.name),
          row: analysis.row,
          col: analysis.col

      {:ok, other} ->
        raise Clr.AllocatorMismatchError,
          original: Clr.Air.Lvalue.as_string(other),
          attempted: Clr.Air.Lvalue.as_string(vtable),
          function: Clr.Air.Lvalue.as_string(analysis.name),
          row: analysis.row,
          col: analysis.col

      :error ->
        raise Clr.AllocatorMismatchError,
          original: :stack,
          attempted: Clr.Air.Lvalue.as_string(vtable),
          function: Clr.Air.Lvalue.as_string(analysis.name),
          row: analysis.row,
          col: analysis.col
    end
  end

  # utility functions

  defp maybe_mark_transferred(analysis, opts) do
    if index = Keyword.get(opts, :passed_as) do
      Block.update_req!(analysis, index, &Keyword.put(&1, :transferred, analysis.name))
    else
      analysis
    end
  end

  defp merge_name({:lvalue, lvalue}, function_name) do
    {:lvalue, List.replace_at(lvalue, -1, function_name)}
  end
end
