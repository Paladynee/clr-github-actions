defmodule Clr.Air.Instruction.TagName do
  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(Clr.Air.Base, ~w[lineref cs dquoted lparen rparen]a)
  Clr.Air.import(Clr.Air.Literal, [:literal])

  Pegasus.parser_from_string(
    "tag_name <- 'tag_name' lparen (literal / lineref) rparen",
    tag_name: [export: true, post_traverse: :tag_name]
  )

  def tag_name(rest, [value, "tag_name"], context, _line, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end
end
