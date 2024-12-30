defmodule Clr.Air.Instruction.Call do
  use Clr.Air.Instruction

  defstruct [:fn, :args]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lvalue fn_literal literal cs lineref lparen rparen lbrack rbrack]a)

  Pegasus.parser_from_string(
    """
    call <- 'call' lparen (fn_literal / lineref) cs lbrack (argument (cs argument)*)? rbrack rparen
    argument <- lineref / literal / lvalue
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

  def analyze(call, line, analysis) do
    case call.fn do
      {:literal, {:fn, [~l"mem.Allocator" | params], type, _fn_opts}, {:function, function}} ->
        process_allocator(function, params, type, call.args, line, analysis)
      {:literal, _type, {:function, function_name}} ->
        # we also need the context of the current function.

        types =
          Enum.map(call.args, fn 
            {:literal, type, _} ->
              type
            {line, _} ->
              Analysis.fetch!(analysis, line)
          end)
    
        analysis.name
        |> merge_name(function_name)
        |> Clr.Analysis.evaluate(types)
        |> case do
          {:future, ref} ->
            analysis
            |> Analysis.put_type(line, {:future, ref})
            |> Analysis.put_future(ref)
    
          {:ok, result} ->
            Analysis.put_type(analysis, line, result)
        end
      end
  end

  defp process_allocator("create" <> _, [], {:errorable, e, {:ptr, count, type, opts}}, [{:literal, ~l"mem.Allocator", struct}], line, analysis) do
    heap_type = {:errorable, e, {:ptr, count, type, Keyword.put(opts, :heap, Map.fetch!(struct, "vtable"))}}
    Analysis.put_type(analysis, line, heap_type)
  end

  defp process_allocator("destroy" <> _, [_], ~l"void", [{:literal, ~l"mem.Allocator", struct}, {src, _}], line, analysis) do
    {:ptr, :one, type, opts} = Analysis.fetch!(analysis, src)
    vtable = Map.fetch!(struct, "vtable")

    case Keyword.fetch(opts, :heap) do
       {:ok, ^vtable} ->
          
        analysis
        |> Analysis.put_type(src, {:ptr, :one, type, Keyword.put(opts, :heap, :deleted)})
        |> Analysis.put_type(line, ~l"void")

      {:ok, :deleted} ->
        raise Clr.DoubleFreeError

      :error -> raise Clr.AllocatorMismatchError
    end
  end

  # utility functions

  defp merge_name({:lvalue, lvalue}, function_name) do
    {:lvalue, List.replace_at(lvalue, -1, function_name)}
  end
end
