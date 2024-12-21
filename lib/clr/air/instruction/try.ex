defmodule Clr.Air.Instruction.Try do
  defstruct [:loc, :error_code, clobbers: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref clobbers cs space lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])
  Clr.Air.import(Clr.Air.Parser, [:codeblock_clobbers])

  Pegasus.parser_from_string(
    """
    try <- 'try' lparen lineref cs codeblock_clobbers (space clobbers)? rparen
    """,
    try: [export: true, post_traverse: :try]
  )

  defp try(rest, [{:clobbers, clobbers}, error_code, loc, "try"], context, _line, _bytes) do
    {rest, [%__MODULE__{loc: loc, error_code: error_code, clobbers: clobbers}], context}
  end
end
