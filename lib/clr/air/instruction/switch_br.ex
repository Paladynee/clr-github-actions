defmodule Clr.Air.Instruction.SwitchBr do
  defstruct [:test, :cases]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[
      slotref cs space lparen rparen lbrack rbrack fatarrow newline elision
      type literal lvalue codeblock_clobbers
    ]a)

  Pegasus.parser_from_string(
    """
    switch_br <- 'switch_br' lparen slotref (cs switch_case)* (cs else_case)? (newline space*)? rparen

    switch_case <- lbrack case_value (cs case_value)* rbrack (space modifier)? space fatarrow space codeblock_clobbers 
    case_value <- range / literal / lvalue
    else_case <- 'else' (space modifier)? space fatarrow space codeblock_clobbers

    range <- (literal / lvalue) elision (literal / lvalue)

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

  defp switch_br(rest, args, context, _slot, _bytes) do
    case Enum.reverse(args) do
      ["switch_br", test | cases] ->
        {rest, [%__MODULE__{test: test, cases: Map.new(cases)}], context}
    end
  end

  @modifiers ~w[cold unlikely]a

  defp switch_case(rest, [codeblock, modifier | compares], context, _slot, _bytes)
       when modifier in @modifiers do
    {rest, [{compares, codeblock}], context}
  end

  defp switch_case(rest, [codeblock, rhs, :..., lhs], context, _slot, _bytes) do
    {rest, [{{:range, lhs, rhs}, codeblock}], context}
  end

  defp switch_case(rest, [codeblock | compares], context, _slot, _bytes) do
    {rest, [{compares, codeblock}], context}
  end

  defp else_case(rest, [codeblock, modifier, "else"], context, _slot, _bytes)
       when modifier in @modifiers do
    {rest, [{:else, codeblock}], context}
  end

  defp else_case(rest, [codeblock, "else"], context, _slot, _bytes) do
    {rest, [{:else, codeblock}], context}
  end
end
