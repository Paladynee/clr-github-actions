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

  def analyze(call, line, analysis) do
    {:literal, _type, {:function, function_name}} = call.fn
    # we also need the context of the current function.

    analysis.name
    |> merge_name(function_name)
    |> Clr.Analysis.evaluate(call.args)
    |> case do
      {:future, ref} -> 
        analysis
        |> Analysis.put_type(line, {:future, ref})
        |> Analysis.put_future(ref)

      {:ok, result} -> Analysis.put_type(analysis, line, result)
    end
  end

  defp merge_name({:lvalue, lvalue}, function_name) do
    {:lvalue, List.replace_at(lvalue, -1, function_name)}
  end
end
