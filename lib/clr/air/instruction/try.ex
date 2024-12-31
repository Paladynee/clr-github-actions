defmodule Clr.Air.Instruction.Try do
  defstruct [:src, :error_code, clobbers: []]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref clobbers cs space lparen rparen type codeblock_clobbers]a)

  Pegasus.parser_from_string(
    """
    try <- 'try' lparen lineref cs codeblock_clobbers (space clobbers)? rparen
    """,
    try: [export: true, post_traverse: :try]
  )

  defp try(rest, [{:clobbers, clobbers}, error_code, src, "try"], context, _line, _bytes) do
    {rest, [%__MODULE__{src: src, error_code: error_code, clobbers: clobbers}], context}
  end

  use Clr.Air.Instruction
  alias Clr.Analysis

  def analyze(%{src: {src, _}}, line, analysis) do
    {:errorable, _, payload} = Analysis.fetch!(analysis, src)
    # for now.  Ultimately, we will need to walk the analysis on this, too.
    Analysis.put_type(analysis, line, payload)
  end
end
