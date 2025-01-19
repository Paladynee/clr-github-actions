defmodule Clr.Air.Instruction.AggregateInit do
  defstruct [:init, :params]

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[argument type literal enum_value lvalue slotref int cs space lparen rparen lbrack rbrack lbrace rbrace notnewline]a
  )

  Pegasus.parser_from_string(
    """
    aggregate_init <- 'aggregate_init' lparen (struct_init / lvalue / type) cs params rparen

    struct_init <- 'struct' space lbrace space initializer (cs initializer)* space rbrace 

    initializer <- assigned_type / type
    assigned_type <- type space '=' space value
    value <- lvalue / int / enum_value

    params <- lbrack argument (cs argument)* rbrack
    """,
    aggregate_init: [post_traverse: :aggregate_init],
    struct_init: [post_traverse: :struct_init],
    initializer: [post_traverse: :initializer],
    params: [post_traverse: :params]
  )

  defp aggregate_init(rest, [params, init, "aggregate_init"], context, _slot, _bytes) do
    {rest, [%__MODULE__{params: params, init: init}], context}
  end

  defp struct_init(rest, params, context, _slot, _bytes) do
    params =
      case Enum.reverse(params) do
        ["struct" | params] -> params
      end

    {rest, [params], context}
  end

  defp initializer(rest, [val, "=", type], context, _slot, _bytes) do
    {rest, [{type, val}], context}
  end

  defp initializer(rest, [type], context, _slot, _bytes) do
    {rest, [type], context}
  end

  defp params(rest, params, context, _slot, _bytes) do
    {rest, [Enum.reverse(params)], context}
  end
end
