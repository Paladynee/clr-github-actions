defmodule Clr.Air.Lvalue do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[type convertible identifier int null undefined elision cs space comma dot lparen rparen lbrack rbrack 
       lbrace rbrace squoted equals notnewline]a
  )

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
    lvalue_segment <- star / vector / (identifier (comptime_call_params)? (array_deref)*) / questionmark

    # function lvalue is a "special function call" that has been defined at the language
    # level, possibly with os / runtime bindings, e.g. 'resetSegfaultHandler'

    function_lvalue <- lparen (function / extern) space squoted rparen

    # comptime calls
    comptime_call_params <- lparen (comptime_call_param (comma comptime_call_param)*)? rparen
    comptime_call_param <- convertible

    # maybe unify this with "literal" content
    comptime_struct <- elided_struct / empty_struct / (dot lbrace (comptime_struct_fields / comptime_tuple_fields) rbrace)
    comptime_tuple_fields <- space comptime_call_param (cs comptime_call_param)* (cs elision)? space
    comptime_struct_fields <- space comptime_struct_field (cs comptime_struct_field)* space
    comptime_struct_field <- dot identifier space equals space comptime_call_param

    # vector is not a normal comptime call, since the parameters are separated
    # with "comma space" instead of "space"
    vector <- '@Vector' lparen int cs type rparen

    array_deref <- lbrack int rbrack
    elided_struct <- '.{ ... }'
    empty_struct <- '.{}'

    function <- 'function'
    extern <- 'extern'
    questionmark <- '?'
    star <- '*'
    """,
    lvalue: [export: true, parser: true],
    basic_lvalue: [export: true, post_traverse: :basic_lvalue],
    lvalue_segment: [post_traverse: :lvalue_segment],
    function_lvalue: [post_traverse: :function_lvalue],
    function: [token: :function],
    extern: [token: :extern],
    comptime_call_params: [post_traverse: :comptime_call_params],
    comptime_struct: [export: true],
    comptime_struct_fields: [post_traverse: :comptime_struct_fields],
    comptime_tuple_fields: [post_traverse: :comptime_tuple_fields],
    vector: [post_traverse: :vector],
    array_deref: [post_traverse: :array_deref],
    elided_struct: [token: :...],
    empty_struct: [token: %{}],
    dot: [ignore: true],
    questionmark: [token: :unwrap_optional],
    star: [token: :pointer_deref]
  )

  @function_types [:function, :extern]

  defp function_lvalue(rest, [name, type], context, _line, _bytes) when type in @function_types do
    {rest, [{type, name}], context}
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

  defp comptime_struct_fields(rest, fields, context, _line, _bytes) do
    {rest, [to_map(fields, %{})], context}
  end

  defp comptime_tuple_fields(rest, fields, context, _line, _bytes) do
    tuple =
      fields
      |> Enum.reverse()
      |> List.to_tuple()

    {rest, [tuple], context}
  end

  defp array_deref(rest, [index], context, _line, _bytes) do
    {rest, [{:array, index}], context}
  end

  defp vector(rest, [type, count, "@Vector"], context, _line, _bytes) do
    {rest, [{:vector, type, count}], context}
  end

  defp to_map([value, key | rest], so_far), do: to_map(rest, Map.put(so_far, key, value))
  defp to_map([], so_far), do: so_far

  def parse(string) do
    case lvalue(string) do
      {:ok, [parsed], "", _, _, _} -> parsed
    end
  end
end
