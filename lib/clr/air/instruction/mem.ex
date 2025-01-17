defmodule Clr.Air.Instruction.Mem do
  require Pegasus

  alias Clr.Air
  require Air

  Air.import(~w[slotref cs lparen rparen type literal argument]a)

  Pegasus.parser_from_string(
    """
    mem <- load
    """,
    mem: [export: true]
  )

  defmodule Load do
    # takes a value from a pointer and puts into a vm slot.
    defstruct [:type, :src]

    use Clr.Air.Instruction

    alias Clr.Block
    alias Clr.Type

    def analyze(%{type: type, src: {src_slot, _}}, slot, block) do
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

  Air.ty_op(:load, Load)
end
