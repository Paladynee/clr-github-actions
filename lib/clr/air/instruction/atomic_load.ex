defmodule Clr.Air.Instruction.AtomicLoad do
  defstruct [:loc, :mode]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref name cs lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    """
    atomic_load <- 'atomic_load' lparen (lineref / literal) cs mode rparen

    mode <- unordered
    unordered <- 'unordered'
    """,
    atomic_load: [export: true, post_traverse: :atomic_load],
    unordered: [token: :unordered]
  )

  def atomic_load(rest, [mode, loc, "atomic_load"], context, _line, _bytes) do
    {rest, [%__MODULE__{mode: mode, loc: loc}], context}
  end
end
