defmodule Clr.Air.Instruction.Math do
  require Pegasus
  require Clr.Air

  Pegasus.parser_from_string(
    """
    math <- binary_instruction / unary_type_instruction / overflow_instruction
    """,
    math: [export: true]
  )

  Clr.Air.import(~w[argument type lineref literal lvalue cs lparen rparen]a)

  # binary instructions

  defmodule Binary do
    defstruct ~w[lhs rhs op]a
  end

  Pegasus.parser_from_string(
    """
    binary_instruction <- binary_op lparen argument cs argument rparen

    binary_op <- add_sat / add_wrap / add / 
                 sub_sat / sub_wrap / sub / 
                 mul_sat / mul_wrap / mul /
                 rem / mod / div_exact / div_trunc /
                 min / max /
                 shl / shr /
                 bit_and / bit_or / xor /
                 bool_or

    add <- 'add'
    add_sat <- 'add_sat'
    add_wrap <- 'add_wrap'
    sub <- 'sub'
    sub_sat <- 'sub_sat'
    sub_wrap <- 'sub_wrap'
    mul <- 'mul'
    mul_sat <- 'mul_sat'
    mul_wrap <- 'mul_wrap'
    rem <- 'rem'
    mod <- 'mod'
    div_exact <- 'div_exact'
    div_trunc <- 'div_trunc'
    min <- 'min'
    max <- 'max'
    shl <- 'shl'
    shr <- 'shr'
    bit_and <- 'bit_and'
    bit_or <- 'bit_or'
    xor <- 'xor'
    bool_or <- 'bool_or'
    """,
    binary_instruction: [post_traverse: :binary_instruction],
    add: [token: :add],
    add_sat: [token: :add_sat],
    add_wrap: [token: :add_wrap],
    sub: [token: :sub],
    sub_sat: [token: :sub_sat],
    sub_wrap: [token: :sub_wrap],
    mul: [token: :mul],
    mul_sat: [token: :mul_sat],
    mul_wrap: [token: :mul_wrap],
    rem: [token: :rem],
    mod: [token: :mod],
    div_exact: [token: :div_exact],
    div_trunc: [token: :div_trunc],
    min: [token: :min],
    max: [token: :max],
    shl: [token: :shl],
    shr: [token: :shr],
    bit_and: [token: :bit_and],
    bit_or: [token: :bit_or],
    xor: [token: :xor],
    bool_or: [token: :bool_or]
  )

  def binary_instruction(rest, [rhs, lhs, op], context, _line, _bytes) do
    {rest, [%Binary{lhs: lhs, rhs: rhs, op: op}], context}
  end

  # Unary + Type operations

  defmodule UnaryTyped do
    defstruct ~w[operand op type]a
  end

  Pegasus.parser_from_string(
    """
    unary_type_instruction <- unary_type_op lparen type cs argument rparen

    unary_type_op <- not / abs / clz

    abs <- 'abs'
    not <- 'not'
    clz <- 'clz'
    """,
    unary_type_instruction: [post_traverse: :unary_type_instruction],
    not: [token: :not],
    abs: [token: :abs],
    clz: [token: :clz]
  )

  def unary_type_instruction(rest, [operand, type, op], context, _line, _bytes) do
    {rest, [%UnaryTyped{operand: operand, type: type, op: op}], context}
  end

  # Overflow operations

  defmodule Overflow do
    defstruct ~w[op type lhs rhs]a
  end

  Pegasus.parser_from_string(
    """
    overflow_instruction <- overflow_op with_overflow lparen type cs argument cs argument rparen
    with_overflow <- '_with_overflow'
    overflow_op <- add / sub / mul / shl
    """,
    with_overflow: [ignore: true],
    overflow_instruction: [post_traverse: :overflow_instruction]
  )

  def overflow_instruction(rest, [rhs, lhs, type, op], context, _line, _bytes) do
    {rest, [%Overflow{lhs: lhs, rhs: rhs, type: type, op: op}], context}
  end
end
