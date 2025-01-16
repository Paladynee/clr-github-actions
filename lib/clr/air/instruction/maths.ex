defmodule Clr.Air.Instruction.Maths do
  require Pegasus
  require Clr.Air

  Pegasus.parser_from_string(
    """
    maths <- binary_instruction / unary_type_instruction / unary_instruction / overflow_instruction
    """,
    maths: [export: true]
  )

  Clr.Air.import(~w[argument type slotref literal lvalue cs lparen rparen]a)

  # binary instructions

  defmodule Binary do
    defstruct ~w[lhs rhs op mode]a
  end

  Pegasus.parser_from_string(
    """
    binary_instruction <- binary_op lparen argument cs argument rparen

    binary_op <- add_op / sub_op / mul_op / div_op / rem_op / mod_op /
                 min / max / shr_op / shl_op/
                 bit_and / bit_or / xor /
                 bool_and / bool_or

    add_op <- add (optimized / safe / sat / wrap)?
    add <- 'add'
    sub_op <- sub (optimized / safe / sat / wrap)?
    sub <- 'sub'
    mul_op <- mul (optimized / safe / sat / wrap)?
    mul <- 'mul'
    div_op <- div_float_op / div_trunc_op / div_floor_op / div_exact_op
    div_exact_op <- div_exact optimized?
    div_float_op <- div_float optimized?
    div_floor_op <- div_floor optimized?
    div_trunc_op <- div_trunc optimized?
    div_float <- 'div_float'
    div_trunc <- 'div_trunc'
    div_floor <- 'div_floor'
    div_exact <- 'div_exact'
    rem_op <- rem optimized?
    mod_op <- mod optimized?
    rem <- 'rem'
    mod <- 'mod'
    min <- 'min'
    max <- 'max'
    shr_op <- shr exact?
    shr <- 'shr'
    shl_op <- shl (exact / sat)?
    shl <- 'shl'
    bit_and <- 'bit_and'
    bit_or <- 'bit_or'
    xor <- 'xor'
    bool_and <- 'bool_and'
    bool_or <- 'bool_or'

    exact <- '_exact'
    safe <- '_safe'
    optimized <- '_optimized'
    wrap <- '_wrap'
    sat <- '_sat'
    """,
    binary_instruction: [post_traverse: :binary_instruction],
    add: [token: :add],
    sub: [token: :sub],
    sub_sat: [token: :sub_sat],
    sub_wrap: [token: :sub_wrap],
    mul: [token: :mul],
    mul_sat: [token: :mul_sat],
    mul_wrap: [token: :mul_wrap],
    div_float: [token: :div_float],
    div_trunc: [token: :div_trunc],
    div_floor: [token: :div_floor],
    div_exact: [token: :div_exact],
    rem: [token: :rem],
    mod: [token: :mod],
    min: [token: :min],
    max: [token: :max],
    shl: [token: :shl],
    shr: [token: :shr],
    bit_and: [token: :bit_and],
    bit_or: [token: :bit_or],
    xor: [token: :xor],
    bool_and: [token: :bool_and],
    bool_or: [token: :bool_or],
    safe: [token: :safe],
    optimized: [token: :optimized],
    sat: [token: :sat],
    wrap: [token: :wrap],
    exact: [token: :exact]
  )

  @modes ~w[safe optimized wrap sat exact]a
  def binary_instruction(rest, [rhs, lhs, mode, op], context, _slot, _bytes)
      when mode in @modes do
    {rest, [%Binary{lhs: lhs, rhs: rhs, op: op, mode: mode}], context}
  end

  def binary_instruction(rest, [rhs, lhs, op], context, _slot, _bytes) do
    {rest, [%Binary{lhs: lhs, rhs: rhs, op: op}], context}
  end

  # Unary + Type operations

  defmodule UnaryTyped do
    defstruct ~w[operand op type]a
  end

  Pegasus.parser_from_string(
    """
    unary_type_instruction <- unary_type_op lparen type cs argument rparen

    unary_type_op <- not / abs / clz / popcount / byte_swap / bit_reverse

    abs <- 'abs'
    not <- 'not'
    clz <- 'clz'
    popcount <- 'popcount'
    byte_swap <- 'byte_swap'
    bit_reverse <- 'bit_reverse'
    """,
    unary_type_instruction: [post_traverse: :unary_type_instruction],
    not: [token: :not],
    abs: [token: :abs],
    clz: [token: :clz],
    popcount: [token: :popcount],
    byte_swap: [token: :byte_swap],
    bit_reverse: [token: :bit_reverse]
  )

  def unary_type_instruction(rest, [operand, type, op], context, _slot, _bytes) do
    {rest, [%UnaryTyped{operand: operand, type: type, op: op}], context}
  end

  # unary operations

  defmodule Unary do
    defstruct ~w[op operand optimized]a
  end

  Pegasus.parser_from_string(
    """
    unary_instruction <- unary_op lparen argument rparen

    unary_op <- sqrt / sin / cos / tan / exp2 / exp / log10 / log2 / log / 
      floor / ceil / round / trunc_float / (neg optimized?)

    sqrt <- 'sqrt'
    sin <- 'sin'
    cos <- 'cos'
    tan <- 'tan'
    exp <- 'exp'
    exp2 <- 'exp2'
    log <- 'log'
    log2 <- 'log2'
    log10 <- 'log10'
    floor <- 'floor'
    ceil <- 'ceil'
    round <- 'round'
    trunc_float <- 'trunc_float'
    neg <- 'neg'
    optimized <- '_optimized'
    """,
    unary_instruction: [post_traverse: :unary_instruction],
    sqrt: [token: :sqrt],
    sin: [token: :sin],
    cos: [token: :cos],
    tan: [token: :tan],
    exp: [token: :exp],
    exp2: [token: :exp2],
    log: [token: :log],
    log2: [token: :log2],
    log10: [token: :log10],
    floor: [token: :floor],
    ceil: [token: :ceil],
    round: [token: :round],
    trunc_float: [token: :trunc_float],
    neg: [token: :neg],
    optimized: [token: :optimized]
  )

  def unary_instruction(rest, args, context, _slot, _bytes) do
    op =
      case args do
        [operand, :optimized, :neg] -> %Unary{operand: operand, op: :neg, optimized: true}
        [operand, operator] -> %Unary{operand: operand, op: operator}
      end

    {rest, [op], context}
  end

  # Overflow operations

  defmodule Overflow do
    use Clr.Air.Instruction
    alias Clr.Block
    alias Clr.Type

    defstruct ~w[op type lhs rhs]a

    def analyze(%{type: type}, slot, analysis),
      do: Block.put_type(analysis, slot, Type.from_air(type))
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

  def overflow_instruction(rest, [rhs, lhs, type, op], context, _slot, _bytes) do
    {rest, [%Overflow{lhs: lhs, rhs: rhs, type: type, op: op}], context}
  end
end
