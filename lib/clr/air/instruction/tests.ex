defmodule Clr.Air.Instruction.Tests do
  require Pegasus
  require Clr.Air

  Pegasus.parser_from_string(
    """
    tests <- compare_instruction / is_instruction / unary_instruction
    """,
    tests: [export: true]
  )

  Clr.Air.import(~w[argument type slotref literal lvalue cs lparen rparen]a)

  # compares

  defmodule Compare do
    use Clr.Air.Instruction

    defstruct ~w[lhs rhs op optimized]a
    import Clr.Air.Lvalue
    alias Clr.Block

    def analyze(_, slot, analysis), do: Block.put_type(analysis, slot, {:bool, %{}})
  end

  Pegasus.parser_from_string(
    """
    compare_instruction <- cmp_prefix compare_op lparen argument cs argument rparen

    cmp_prefix <- 'cmp_'

    compare_op <- (eq / gte / gt / lte / lt / neq) optimized?

    neq <- 'neq'
    lt <- 'lt'
    lte <- 'lte'
    eq <- 'eq'
    gt <- 'gt'
    gte <- 'gte'
    optimized <- '_optimized'
    """,
    compare_instruction: [post_traverse: :compare_instruction],
    cmp_prefix: [ignore: true],
    neq: [token: :neq],
    lt: [token: :lt],
    lte: [token: :lte],
    eq: [token: :eq],
    gt: [token: :gt],
    gte: [token: :gte],
    optimized: [token: :optimized]
  )

  def compare_instruction(rest, [rhs, lhs, op], context, _slot, _bytes) do
    {rest, [%Compare{lhs: lhs, rhs: rhs, op: op}], context}
  end

  def compare_instruction(rest, [rhs, lhs, :optimized, op], context, _slot, _bytes) do
    {rest, [%Compare{lhs: lhs, rhs: rhs, op: op, optimized: true}], context}
  end

  defmodule Is do
    defstruct ~w[operand op]a
  end

  Pegasus.parser_from_string(
    """
    is_instruction <- is_prefix is_op lparen argument rparen

    is_prefix <- 'is_'

    is_op <- err_ptr / err / non_err_ptr / non_err / non_null_ptr / non_null / null_ptr / null

    null <- 'null'
    non_null <- 'non_null'
    null_ptr <- 'null_ptr'
    non_null_ptr <- 'non_null_ptr'
    err <- 'err'
    non_err <- 'non_err'
    err_ptr <- 'err_ptr'
    non_err_ptr <- 'non_err_ptr'
    """,
    is_instruction: [post_traverse: :is_instruction],
    is_prefix: [ignore: true],
    null: [token: :null],
    non_null: [token: :non_null],
    null_ptr: [token: :null_ptr],
    non_null_ptr: [token: :non_null_ptr],
    err: [token: :err],
    non_err: [token: :non_err],
    err_ptr: [token: :err_ptr],
    non_err_ptr: [token: :non_err_ptr]
  )

  def is_instruction(rest, [operand, op], context, _slot, _bytes) do
    {rest, [%Is{operand: operand, op: op}], context}
  end

  defmodule Unary do
    defstruct ~w[operand op]a
  end

  Pegasus.parser_from_string(
    """
    unary_instruction <- unary_op lparen argument rparen

    unary_op <- cmp_lt_errors_len

    cmp_lt_errors_len <- 'cmp_lt_errors_len'
    """,
    unary_instruction: [post_traverse: :unary_instruction],
    unary_prefix: [ignore: true],
    cmp_lt_errors_len: [token: :cmp_lt_errors_len]
  )

  def unary_instruction(rest, [operand, op], context, _slot, _bytes) do
    {rest, [%Unary{operand: operand, op: op}], context}
  end
end
