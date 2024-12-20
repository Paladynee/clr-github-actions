defmodule Clr.Air.Lvalue do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[identifier int cs space comma dot lparen rparen lbrack rbrack squoted notnewline]a
  )

  Clr.Air.import(Clr.Air.Type, [:type])

  defmacro sigil_l({:<<>>, _, [type]}, _) do
    values = String.split(type, ".")

    quote do
      {:lvalue, unquote(values)}
    end
  end

  Pegasus.parser_from_string(
    """
    lvalue <- function_lvalue / basic_lvalue
    basic_lvalue <- lvalue_segment (dot lvalue_segment)*
    lvalue_segment <- (identifier (comptime_call_params)? (array_deref)*) / questionmark

    # function lvalue is a "special function call" that has been defined at the language
    # level, possibly with os / runtime bindings, e.g. 'resetSegfaultHandler'

    function_lvalue <- lparen function space squoted rparen

    # comptime calls
    comptime_call_params <- lparen (comptime_call_param (comma comptime_call_param)*)? rparen
    comptime_call_param <- int / type / basic_lvalue

    array_deref <- lbrack int rbrack

    function <- 'function'
    questionmark <- '?'
    """,
    lvalue: [export: true, parser: true],
    basic_lvalue: [export: true, post_traverse: :basic_lvalue],
    lvalue_segment: [post_traverse: :lvalue_segment],
    function_lvalue: [post_traverse: :function_lvalue],
    function: [token: :function],
    comptime_call_params: [post_traverse: :comptime_call_params],
    array_deref: [post_traverse: :array_deref],
    dot: [ignore: true],
    questionmark: [token: :unwrap_optional]
  )

  defp function_lvalue(rest, [name, :function], context, _line, _bytes) do
    {rest, [{:function, name}], context}
  end

  defp basic_lvalue(rest, args, context, _line, _bytes) do
    {rest, [coalesce_lvalue(args, [])], context}
  end

  defp coalesce_lvalue([head | rest], [{:comptime_call, {:lvalue, call}, params} | rest_so_far]) do
    coalesce_lvalue(rest, [{:comptime_call, {:lvalue, [head | call]}, params} | rest_so_far])
  end

  defp coalesce_lvalue([head | rest], so_far) do
    coalesce_lvalue(rest, [head | so_far])
  end

  defp coalesce_lvalue([], so_far), do: {:lvalue, so_far}

  defp lvalue_segment(rest, args, context, _line, _bytes) do
    {rest, coalesce_lvalue_segment(args), context}
  end

  defp coalesce_lvalue_segment([{:array, index} | rest]) do
    [index | coalesce_lvalue_segment(rest)]
  end

  defp coalesce_lvalue_segment([{:call, calls}, parent]) do
    [{:comptime_call, {:lvalue, [parent]}, calls}]
  end

  defp coalesce_lvalue_segment([parent]), do: [parent]

  defp comptime_call_params(rest, args, context, _line, _bytes) do
    {rest, [{:call, Enum.reverse(args)}], context}
  end

  defp array_deref(rest, [index], context, _line, _bytes) do
    {rest, [{:array, index}], context}
  end

  def parse(string) do
    case lvalue(string) do
      {:ok, [parsed], "", _, _, _} -> parsed
    end
  end
end
