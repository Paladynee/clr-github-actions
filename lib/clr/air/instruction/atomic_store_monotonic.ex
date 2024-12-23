defmodule Clr.Air.Instruction.AtomicStoreMonotonic do
  defstruct [:loc, :val, :mode]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    """
    atomic_store_monotonic <- 'atomic_store_monotonic' lparen (lineref / literal) cs (lineref / literal) cs mode rparen

    mode <- monotonic
    monotonic <- 'monotonic'
    """,
    atomic_store_monotonic: [export: true, post_traverse: :atomic_store_monotonic],
    monotonic: [token: :monotonic]
  )

  def atomic_store_monotonic(
        rest,
        [mode, val, loc, "atomic_store_monotonic"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{mode: mode, val: val, loc: loc}], context}
  end
end
