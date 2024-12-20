defmodule Clr.Air.Instruction.CondBr do
  defstruct [:cond, :true_branch, :false_branch]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs space lparen rparen]a)
  Clr.Air.import(Clr.Air.Type, [:type])
  Clr.Air.import(Clr.Air.Parser, [:codeblock_clobbers])

  Pegasus.parser_from_string(
    """
    cond_br <- 'cond_br' lparen lineref cs branch cs branch rparen

    branch <- branchtype space codeblock_clobbers
    branchtype <- likelypoi / coldpoi / likely / cold / poi 

    poi <- 'poi'
    likely <- 'likely'
    cold <- 'cold'
    likelypoi <- 'likely poi'
    coldpoi <- 'cold poi'
    """,
    cond_br: [export: true, post_traverse: :cond_br],
    poi: [token: :poi],
    likely: [token: :likely],
    cold: [token: :cold],
    likelypoi: [token: :likelypoi],
    coldpoi: [token: :coldpoi]
  )

  def cond_br(
        rest,
        [false_branch, _false_type, true_branch, _true_type, lineref, "cond_br"],
        context,
        _line,
        _bytes
      ) do
    {rest, [%__MODULE__{cond: lineref, true_branch: true_branch, false_branch: false_branch}],
     context}
  end
end
