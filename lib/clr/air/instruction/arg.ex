defmodule Clr.Air.Instruction.Arg do
  use Clr.Air.Instruction

  defstruct [:type, :name]

  require Pegasus
  require Clr.Air
  alias Clr.Block
  alias Clr.Type

  Clr.Air.import(~w[type int cs dquoted lparen rparen]a)

  Pegasus.parser_from_string(
    "arg <- 'arg' lparen type (cs dquoted)? rparen",
    arg: [export: true, post_traverse: :arg]
  )

  def arg(rest, [type, "arg"], context, _slot, _byte) do
    {rest, [%__MODULE__{type: type}], context}
  end

  def arg(rest, [name, type, "arg"], context, _slot, _byte) do
    {rest, [%__MODULE__{type: type, name: name}], context}
  end

  def analyze(%{type: type}, slot, block) do
    # note that metadata is conveyed through the args_meta
    arg_meta = Enum.at(block.args_meta, slot) || raise "unreachable"
    Block.put_type(block, slot, Type.from_air(type), arg_meta)
  end
end
