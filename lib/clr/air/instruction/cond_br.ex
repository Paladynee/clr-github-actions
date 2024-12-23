defmodule Clr.Air.Instruction.CondBr do
  defstruct [:cond, :true_branch, :false_branch]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref cs space lparen rparen type codeblock_clobbers]a)

  Pegasus.parser_from_string(
    """
    cond_br <- 'cond_br' lparen lineref cs branch cs branch rparen

    branch <- branchtype space codeblock_clobbers
    branchtype <- likelypoi / unlikelypoi / coldpoi / likely / unlikely / cold / poi 

    poi <- 'poi'
    likely <- 'likely'
    unlikely <- 'unlikely'
    cold <- 'cold'
    likelypoi <- 'likely poi'
    unlikelypoi <- 'unlikely poi'
    coldpoi <- 'cold poi'
    """,
    cond_br: [export: true, post_traverse: :cond_br],
    poi: [token: :poi],
    likely: [token: :likely],
    cold: [token: :cold],
    likelypoi: [token: :likelypoi],
    coldpoi: [token: :coldpoi],
    unlikely: [token: :unlikely],
    unlikelypoi: [token: :unlikelypoi]
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
