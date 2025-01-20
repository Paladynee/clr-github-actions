defmodule Clr.Air.Instruction.Vector do
  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument type slotref literal lvalue cs lparen rparen int space]a)

  Pegasus.parser_from_string("vector <- reduce / cmp_vector / select / shuffle # splat\n",
    vector: [export: true]
  )

  defmodule Reduce do
    defstruct [:src, :op, :optimized]
  end

  Pegasus.parser_from_string(
    """
    reduce <- reduce_str optimized? lparen slotref cs op rparen

    reduce_str <- 'reduce'
    optimized <- '_optimized'

    op <- add / sub / or
    add <- 'Add'
    sub <- 'Sub'
    or <- 'Or'
    """,
    reduce: [post_traverse: :reduce],
    reduce_str: [ignore: true],
    optimized: [token: :optimized],
    add: [token: :add],
    sub: [token: :sub],
    or: [token: :or]
  )

  def reduce(rest, [op, src | rest_args], context, _slot, _bytes) do
    optimized =
      case rest_args do
        [] -> false
        [:optimized] -> true
      end

    {rest, [%Reduce{op: op, src: src, optimized: optimized}], context}
  end

  defmodule Cmp do
    defstruct [:op, :lhs, :rhs, :optimized]
  end

  Pegasus.parser_from_string(
    """
    cmp_vector <- cmp_vector_str optimized? lparen cmp_op cs argument cs argument rparen
    cmp_vector_str <- 'cmp_vector'

    cmp_op <- lte / lt / gte / gt / neq / eq
    lte <- 'lte'
    lt <- 'lt'
    gte <- 'gte'
    gt <- 'gt'
    eq <- 'eq'
    neq <- 'neq'
    """,
    cmp_vector: [post_traverse: :cmp_vector],
    cmp_vector_str: [ignore: true],
    optimized: [token: :optimized],
    lte: [token: :lte],
    lt: [token: :lt],
    gte: [token: :gte],
    gt: [token: :gt],
    eq: [token: :eq],
    neq: [token: :neq]
  )

  def cmp_vector(rest, [rhs, lhs, op | rest_args], context, _slot, _bytes) do
    optimized =
      case rest_args do
        [] -> false
        [:optimized] -> true
      end

    {rest, [%Cmp{op: op, lhs: lhs, rhs: rhs, optimized: optimized}], context}
  end

  defmodule Splat do
  end

  defmodule Shuffle do
    defstruct [:a, :b, :len, :mask]
  end

  Pegasus.parser_from_string(
    """
    shuffle <- shuffle_str lparen argument cs argument cs mask space lvalue cs len space int rparen
    shuffle_str <- 'shuffle'
    mask <- 'mask'
    len <- 'len'
    """,
    shuffle: [post_traverse: :shuffle],
    shuffle_str: [ignore: true],
    mask: [ignore: true],
    len: [ignore: true],
  )

  def shuffle(rest, [len, mask, b, a], context, _slot, _bytes) do
    {rest, [%Shuffle{a: a, b: b, len: len, mask: mask}], context}
  end

  defmodule Select do
    defstruct [:type, :pred, :a, :b]
  end

  Pegasus.parser_from_string(
    """
    select <- select_str lparen type cs argument cs argument cs argument rparen
    select_str <- 'select'
    """,
    select: [post_traverse: :select],
    select_str: [ignore: true]
  )

  def select(rest, [b, a, pred, type], context, _slot, _bytes) do
    {rest, [%Select{type: type, pred: pred, a: a, b: b}], context}
  end

end
