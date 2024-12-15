defmodule Clr.Air.Instruction.SwitchBr do
  defstruct [:test, :cases]

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[lineref name cs space lparen rparen lbrack rbrack fatarrow newline]a
  )

  Clr.Air.import(Clr.Air.Type, ~w[type fn_literal int_literal]a)

  Clr.Air.import(Clr.Air.Parser, [:codeblock_clobbers])

  Pegasus.parser_from_string(
    """
    switch_br <- 'switch_br' lparen lineref (cs switch_case)* (cs else_case)? (newline space*)? rparen

    switch_case <- lbrack int_literal (cs int_literal)* rbrack space fatarrow space codeblock_clobbers 
    else_case <- 'else' space fatarrow space codeblock_clobbers
    """,
    switch_br: [export: true, post_traverse: :switch_br],
    switch_case: [post_traverse: :switch_case],
    else_case: [post_traverse: :else_case]
  )

  defp switch_br(rest, args, context, _line, _bytes) do
    case Enum.reverse(args) do
      ["switch_br", test | cases] ->
        {rest, [%__MODULE__{test: test, cases: Map.new(cases)}], context}
    end
  end

  defp switch_case(rest, [codeblock | compares], context, _line, _bytes) do
    {rest, [{compares, codeblock}], context}
  end

  defp else_case(rest, [codeblock, "else"], context, _line, _bytes) do
    {rest, [{:else, codeblock}], context}
  end
end
