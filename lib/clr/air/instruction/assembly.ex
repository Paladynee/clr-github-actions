defmodule Clr.Air.Instruction.Assembly do
  defstruct [:type, :in1, :in2, :code]

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[name cs space lparen rparen lbrack rbrack dstring]a
  )

  Clr.Air.import(Clr.Air.Type, ~w[type fn_literal]a)

  Pegasus.parser_from_string(
    """
    assembly <- 'assembly' lparen type cs asmtype cs asm_in cs asm_in cs dstring rparen
    asmtype <- volatile
    volatile <- 'volatile'

    asm_in <- lbrack name rbrack space 'in' space name space '=' space lparen fn_literal rparen
    """,
    assembly: [export: true, post_traverse: :assembly],
    asm_in: [post_traverse: :asm_in],
    volatile: [token: :volatile]
  )

  defp asm_in(rest, [literal, "=", var, "in" | args], context, _line, _bytes) do
    {rest, [{:in, var, Enum.reverse(args), literal}], context}
  end

  defp assembly(rest, [asm, in2, in1, :volatile, type, "assembly"], context, _line, _bytes) do
    {rest, [%__MODULE__{code: asm, in2: in2, in1: in1, type: type}], context}
  end
end
