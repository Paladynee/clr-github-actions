defmodule Clr.Air.Instruction.AtomicStoreUnordered do
  defstruct [:loc, :val, :mode]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    """
    atomic_store_unordered <- 'atomic_store_unordered' lparen lineref cs (lineref / literal) cs mode rparen

    mode <- unordered
    unordered <- 'unordered'
    """,
    atomic_store_unordered: [export: true, post_traverse: :atomic_store_unordered],
    unordered: [token: :unordered]
  )

  def atomic_store_unordered(
        rest,
        [mode, val, loc, "atomic_store_unordered"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{mode: mode, val: val, loc: loc}], context}
  end
end
