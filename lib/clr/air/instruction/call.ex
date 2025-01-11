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

  alias Clr.Analysis
  import Clr.Air.Lvalue

  def analyze(call, slot, analysis) do
    case call.fn do
      {:literal, {:fn, [~l"mem.Allocator" | params], type, _fn_opts}, {:function, function}} ->
        process_allocator(function, params, type, call.args, slot, analysis)

      {:literal, _type, {:function, function_name}} ->
        # we also need the context of the current function.

        types =
          Enum.map(call.args, fn
            {:literal, type, _} ->
              type

            {slot, _} ->
              Analysis.fetch!(analysis, slot)
          end)

        analysis.name
        |> merge_name(function_name)
        |> Clr.Analysis.evaluate(types)
        |> case do
          {:future, ref} ->
            analysis
            |> Analysis.put_type(slot, {:future, ref})
            |> Analysis.put_future(ref)

          {:ok, result} ->
            Analysis.put_type(analysis, slot, result)
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

    Analysis.put_type(analysis, slot, heap_type)
  end

  defp process_allocator(
         "destroy" <> _,
         [_],
         ~l"void",
         [{:literal, ~l"mem.Allocator", struct}, {src, _}],
         slot,
         analysis
       ) do
    {:ptr, :one, type, opts} = Analysis.fetch!(analysis, src)
    vtable = Map.fetch!(struct, "vtable")

    case Keyword.fetch(opts, :heap) do
      {:ok, ^vtable} ->
        analysis
        |> Analysis.put_type(src, {:ptr, :one, type, Keyword.put(opts, :heap, :deleted)})
        |> Analysis.put_type(slot, ~l"void")
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
      Analysis.update_req!(analysis, index, &Keyword.put(&1, :transferred, analysis.name))
    else
      analysis
    end
  end

  defp merge_name({:lvalue, lvalue}, function_name) do
    {:lvalue, List.replace_at(lvalue, -1, function_name)}
  end
end
