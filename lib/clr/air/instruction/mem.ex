defmodule Clr.Air.Instruction.Mem do
  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs lparen rparen type literal]a)

  Pegasus.parser_from_string(
    """
    mem <- load
    """,
    mem: [export: true]
  )

  defmodule Load do
    # takes a value from a pointer and puts into a vm slot.
    defstruct [:type, :loc]

    use Clr.Air.Instruction

    alias Clr.Block
    alias Clr.Type

    def analyze(%{type: type, loc: {src_slot, _}}, slot, block) do
      case Block.fetch_up!(block, src_slot) do
        {{:ptr, _, _, %{undefined: _src}}, block} ->
          raise Clr.UndefinedUsage,
            function: Clr.Air.Lvalue.as_string(block.function),
            loc: block.loc

        {{:ptr, _, _, %{deleted: _src}}, block} ->
          raise Clr.UseAfterFreeError,
            function: Clr.Air.Lvalue.as_string(block.function),
            loc: block.loc

        {{:ptr, _, _, _}, block} ->
          Block.put_type(block, slot, Type.from_air(type))
      end
    end
  end

  Pegasus.parser_from_string(
    """
    load <- load_str lparen type cs (slotref / literal) rparen
    load_str <- 'load'
    """,
    load: [post_traverse: :load],
    load_str: [ignore: true]
  )

  def load(rest, [loc, type], context, _slot, _bytes) do
    {rest, [%Load{type: type, loc: loc}], context}
  end
end
