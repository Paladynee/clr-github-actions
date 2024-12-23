defmodule Clr.Air.Instruction.TryPtr do
  defstruct [:loc, :type, code: %{}, clobbers: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref clobbers cs space lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])
  Clr.Air.import(Clr.Air.Parser, [:codeblock_clobbers])

  Pegasus.parser_from_string(
    """
    try_ptr <- 'try_ptr' lparen lineref cs type cs codeblock_clobbers (space clobbers)? rparen
    """,
    try_ptr: [export: true, post_traverse: :try_ptr]
  )

  defp try_ptr(rest, [{:clobbers, clobbers}, code, type, loc, "try_ptr"], context, _line, _bytes) do
    {rest, [%__MODULE__{loc: loc, type: type, code: code, clobbers: clobbers}], context}
  end
end
