defmodule Clr.Air.Instruction.AtomicRmw do
  defstruct [:dst, :val, :op, :mode]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    """
    atomic_rmw <- 'atomic_rmw' lparen literal cs lvalue cs op cs mode rparen

    op <- add
    add <- 'Add'

    mode <- seq_cst
    seq_cst <- 'seq_cst'
    """,
    atomic_rmw: [export: true, post_traverse: :atomic_rmw],
    add: [token: :add],
    seq_cst: [token: :seq_cst]
  )

  def atomic_rmw(rest, [mode, op, val, dst, "atomic_rmw"], context, _line, _bytes) do
    {rest, [%__MODULE__{mode: mode, op: op, val: val, dst: dst}], context}
  end
end
