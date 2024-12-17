defmodule Clr.Air.Lvalue do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[identifier int cs space dot lparen rparen lbrack rbrack squoted]a
  )

  Clr.Air.import(Clr.Air.Type, [:comptime_call_type])

  defmacro sigil_l({:<<>>, _, [type]}, _) do
    values = String.split(type, ".")

    quote do
      {:lvalue, unquote(values)}
    end
  end

  Pegasus.parser_from_string(
    """
    lvalue <- function_lvalue / function_call / basic_lvalue
    basic_lvalue <- identifier (struct_deref / array_deref)?

    # an lvalue may be a function call if it's a type-generating function that has a dereferenced parameter.
    function_call <- comptime_call_type function_continuation
    function_continuation <- dot (function_call / basic_lvalue)

    functionparam <- int / lvalue

    function_lvalue <- lparen function space squoted rparen
    struct_deref <- dot basic_lvalue
    array_deref <- lbrack int rbrack (lbrack int rbrack)*

    function <- 'function'
    """,
    lvalue: [export: true, parser: true, post_traverse: :lvalue],
    basic_lvalue: [export: true],
    function: [token: :function],
    dot: [ignore: true]
  )

  defp lvalue(rest, [name, :function], context, _line, _bytes) do
    {rest, [{:function, name}], context}
  end

  defp lvalue(rest, values, context, _line, _bytes) do
    {rest, [{:lvalue, Enum.reverse(values)}], context}
  end

  def parse(string) do
    case lvalue(string) do
      {:ok, [parsed], "", _, _, _} -> parsed
    end
  end
end
