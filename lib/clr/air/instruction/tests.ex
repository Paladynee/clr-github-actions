defmodule Clr.Air.Instruction.Tests do
  require Pegasus
  require Clr.Air

  Pegasus.parser_from_string(
    """
    tests <- compare_instruction
    """,
    tests: [export: true]
  )

  Clr.Air.import(~w[argument type lineref literal lvalue cs lparen rparen]a)

  # compares

  defmodule Compare do
    defstruct ~w[lhs rhs op]a
  end

  Pegasus.parser_from_string(
    """
    compare_instruction <- cmp_prefix op lparen argument cs argument rparen

    cmp_prefix <- 'cmp_'

    op <- eq / gte / gt / lte / lt / neq

    neq <- 'neq'
    lt <- 'lt'
    lte <- 'lte'
    eq <- 'eq'
    gt <- 'gt'
    gte <- 'gte'
    """,
    compare_instruction: [post_traverse: :compare_instruction],
    cmp_prefix: [ignore: true],
    neq: [token: :neq],
    lt: [token: :lt],
    lte: [token: :lte],
    eq: [token: :eq],
    gt: [token: :gt],
    gte: [token: :gte]
  )

  def compare_instruction(rest, [rhs, lhs, op], context, _line, _bytes) do
    {rest, [%Compare{lhs: lhs, rhs: rhs, op: op}], context}
  end
end
