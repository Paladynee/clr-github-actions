defmodule Clr.Air.Instruction.AtomicRmw do
  defstruct [:loc, :val, :op, :mode]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[type lvalue literal lineref cs lparen rparen]a)

  Pegasus.parser_from_string(
    """
    atomic_rmw <- 'atomic_rmw' lparen (lineref / lvalue / literal) cs (lineref / lvalue / literal) cs op cs mode rparen

    op <- add / sub / or / xchg
    add <- 'Add'
    sub <- 'Sub'
    or <- 'Or'
    xchg <- 'Xchg'

    mode <- seq_cst / release / acquire
    seq_cst <- 'seq_cst'
    release <- 'release'
    acquire <- 'acquire'
    """,
    atomic_rmw: [export: true, post_traverse: :atomic_rmw],
    add: [token: :add],
    sub: [token: :sub],
    or: [token: :or],
    xchg: [token: :xchg],
    seq_cst: [token: :seq_cst],
    release: [token: :release],
    acquire: [token: :acquire]
  )

  def atomic_rmw(rest, [mode, op, val, loc, "atomic_rmw"], context, _line, _bytes) do
    {rest, [%__MODULE__{mode: mode, op: op, loc: loc, val: val}], context}
  end
end
