defmodule Clr.Air.Instruction.SwitchBr do
  defstruct [:test, :cases]

  require Pegasus
  require Clr.Air

  Clr.Air.import(
    Clr.Air.Base,
    ~w[lineref name cs space lparen rparen lbrack rbrack fatarrow newline elision]a
  )

  Clr.Air.import(Clr.Air.Type, ~w[type]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])
  Clr.Air.import(Clr.Air.Lvalue, [:lvalue])

  Clr.Air.import(Clr.Air.Parser, [:codeblock_clobbers])

  Pegasus.parser_from_string(
    """
    switch_br <- 'switch_br' lparen lineref (cs switch_case)* (cs else_case)? (newline space*)? rparen

    switch_case <- lbrack case_value (cs case_value)* rbrack (space modifier)? space fatarrow space codeblock_clobbers 
    case_value <- range / literal / lvalue
    else_case <- 'else' (space modifier)? space fatarrow space codeblock_clobbers

    range <- literal elision literal

    modifier <- cold / unlikely

    unlikely <- '.unlikely'
    cold <- '.cold'
    """,
    switch_br: [export: true, post_traverse: :switch_br],
    switch_case: [post_traverse: :switch_case],
    else_case: [post_traverse: :else_case],
    cold: [token: :cold],
    unlikely: [token: :unlikely]
  )

  defp switch_br(rest, args, context, _line, _bytes) do
    case Enum.reverse(args) do
      ["switch_br", test | cases] ->
        {rest, [%__MODULE__{test: test, cases: Map.new(cases)}], context}
    end
  end

  @modifiers ~w[cold unlikely]a

  defp switch_case(rest, [codeblock, modifier | compares], context, _line, _bytes)
       when modifier in @modifiers do
    {rest, [{compares, codeblock}], context}
  end

  defp switch_case(rest, [codeblock, rhs, :..., lhs], context, _line, _bytes) do
    {rest, [{{:range, lhs, rhs}, codeblock}], context}
  end

  defp switch_case(rest, [codeblock | compares], context, _line, _bytes) do
    {rest, [{compares, codeblock}], context}
  end

  defp else_case(rest, [codeblock, modifier, "else"], context, _line, _bytes)
       when modifier in @modifiers do
    {rest, [{:else, codeblock}], context}
  end

  defp else_case(rest, [codeblock, "else"], context, _line, _bytes) do
    {rest, [{:else, codeblock}], context}
  end
end
