defmodule Clr.Air.Instruction.Math do
  defmodule Binary do
    defstruct ~w[lhs rhs op]a
  end

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument lineref literal lvalue cs lparen rparen]a)

  Pegasus.parser_from_string(
    """
    math <- binary_instruction
      
    binary_instruction <- binary_op lparen argument cs argument rparen

    binary_op <- add_sat / add_wrap / add / sub_sat / sub_wrap / sub
    add <- 'add'
    add_sat <- 'add_sat'
    add_wrap <- 'add_wrap'
    sub_sat <- 'sub_sat'
    sub_wrap <- 'sub_wrap'
    sub <- 'sub'
    """,
    math: [export: true],
    binary_instruction: [post_traverse: :binary_instruction],
    add: [token: :add],
    add_sat: [token: :add_sat],
    add_wrap: [token: :add_wrap],
    sub: [token: :sub],
    sub_sat: [token: :sub_sat],
    sub_wrap: [token: :sub_wrap]
  )

  def binary_instruction(rest, [rhs, lhs, op], context, _line, _bytes) do
    {rest, [%Binary{lhs: lhs, rhs: rhs, op: op}], context}
  end
end
