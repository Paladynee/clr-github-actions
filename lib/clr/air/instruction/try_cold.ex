defmodule Clr.Air.Instruction.TryCold do
  defstruct [:loc, :error_code, clobbers: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref clobbers cs space lparen rparen type codeblock_clobbers]a)

  Pegasus.parser_from_string(
    """
    try_cold <- 'try_cold' lparen slotref cs codeblock_clobbers (space clobbers)? rparen
    """,
    try_cold: [export: true, post_traverse: :try_cold]
  )

  defp try_cold(
         rest,
         [{:clobbers, clobbers}, error_code, loc, "try_cold"],
         context,
         _slot,
         _bytes
       ) do
    {rest, [%__MODULE__{loc: loc, error_code: error_code, clobbers: clobbers}], context}
  end
end
