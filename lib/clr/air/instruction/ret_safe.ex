defmodule Clr.Air.Instruction.RetSafe do
  use Clr.Air.Instruction

  defstruct [:val]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument slotref cs lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    "ret_safe <- 'ret_safe' lparen argument rparen",
    ret_safe: [export: true, post_traverse: :ret_safe]
  )

  def ret_safe(rest, [value, "ret_safe"], context, _slot, _bytes) do
    {rest, [%__MODULE__{val: value}], context}
  end

  alias Clr.Block

  def analyze(%{val: {:lvalue, _} = lvalue}, _dst_slot, block) do
    Block.put_return(block, {:TypeOf, lvalue})
  end

  def analyze(%{val: {:literal, type, _}}, _dst_slot, block) do
    Block.put_return(block, type)
  end

  def analyze(%{val: {src_slot, _}}, _dst_slot, %{function: function} = block) do
    case Block.fetch_up!(block, src_slot) do
      {{:ptr, _, _, %{stack: ^function}}, block} ->
        raise Clr.StackPtrEscape,
          function: Clr.Air.Lvalue.as_string(function),
          loc: block.loc

      {type, block} ->
        Block.put_return(block, type)
    end
  end
end
