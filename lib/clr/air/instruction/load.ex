defmodule Clr.Air.Instruction.Load do
  # takes a value from a pointer and puts into a vm slot.

  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs lparen rparen type literal]a)

  Pegasus.parser_from_string(
    "load <- 'load' lparen type cs (slotref / literal) rparen",
    load: [export: true, post_traverse: :load]
  )

  def load(rest, [loc, type, "load"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, loc: loc}], context}
  end

  use Clr.Air.Instruction

  alias Clr.Block

  def analyze(%{type: type, loc: {src_slot, _}}, slot, block) do
    case Block.fetch_up!(block, src_slot) do
      {{_, %{undefined: _src}}, block} ->
        raise Clr.UndefinedUsage,
          function: Clr.Air.Lvalue.as_string(block.function),
          loc: block.loc

      {{_, %{deleted: _src}}, block} ->
        raise Clr.UseAfterFreeError,
          function: Clr.Air.Lvalue.as_string(block.function),
          loc: block.loc

      {{{:ptr, _, _, _}, _}, block} ->
        Block.put_type(block, slot, type)
    end
  end
end
