defmodule Clr.Air.Instruction.Vector do
  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument type slotref literal lvalue cs lparen rparen]a)

  Pegasus.parser_from_string("vector <- reduce # splat shuffle select\n", vector: [export: true])

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

  defmodule Splat do
  end

  defmodule Shuffle do
  end

  defmodule Select do
  end
end
