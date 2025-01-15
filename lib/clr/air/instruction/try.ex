defmodule Clr.Air.Instruction.Try do
  defstruct [:src, :error_code, clobbers: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref clobbers cs space lparen rparen type codeblock_clobbers]a)

  Pegasus.parser_from_string(
    """
    try <- 'try' lparen slotref cs codeblock_clobbers (space clobbers)? rparen
    """,
    try: [export: true, post_traverse: :try]
  )

  defp try(rest, [{:clobbers, clobbers}, error_code, src, "try"], context, _slot, _bytes) do
    {rest, [%__MODULE__{src: src, error_code: error_code, clobbers: clobbers}], context}
  end

  use Clr.Air.Instruction
  alias Clr.Block

  def analyze(%{src: {src, _}}, slot, block) do
    {{:errorable, _, payload, _meta}, block} = Block.fetch_up!(block, src)
    # for now.  Ultimately, we will need to walk the analysis on this, too.
    Block.put_type(block, slot, payload)
  end
end
