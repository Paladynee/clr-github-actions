defmodule Clr.Air.Instruction.AggregateInit do
  defstruct [:init, :params]

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[lineref int cs space lparen rparen lbrack rbrack lbrace rbrace notnewline]a
  )

  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Literal, ~w[literal enum_value]a)
  Clr.Air.import(Clr.Air.Lvalue, ~w[lvalue]a)

  Pegasus.parser_from_string(
    """
    aggregate_init <- 'aggregate_init' lparen (struct_init / lvalue) cs params rparen

    struct_init <- 'struct' space lbrace space initializer (cs initializer)* space rbrace 

    initializer <- assigned_type / type
    assigned_type <- type space '=' space value
    value <- lvalue / int / enum_value

    params <- lbrack param (cs param)* rbrack
    param <- literal / lvalue / lineref
    """,
    aggregate_init: [export: true, post_traverse: :aggregate_init],
    struct_init: [post_traverse: :struct_init],
    initializer: [post_traverse: :initializer],
    params: [post_traverse: :params]
  )

  defp aggregate_init(rest, [params, init, "aggregate_init"], context, _line, _bytes) do
    {rest, [%__MODULE__{params: params, init: init}], context}
  end

  defp struct_init(rest, params, context, _line, _bytes) do
    params =
      case Enum.reverse(params) do
        ["struct" | params] -> params
      end

    {rest, [params], context}
  end

  defp initializer(rest, [val, "=", type], context, _line, _bytes) do
    {rest, [{type, val}], context}
  end

  defp initializer(rest, [type], context, _line, _bytes) do
    {rest, [type], context}
  end

  defp params(rest, params, context, _line, _bytes) do
    {rest, [Enum.reverse(params)], context}
  end
end
