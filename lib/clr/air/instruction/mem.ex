defmodule Clr.Air.Instruction.Mem do
  require Pegasus

  alias Clr.Air
  require Air

  Air.import(~w[slotref cs lparen rparen type literal argument]a)

  Pegasus.parser_from_string(
    """
    mem <- load / store
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

  defmodule Store do
    defstruct [:loc, :src]
  end

  Pegasus.parser_from_string(
    """
    store <- store_str safe? lparen (slotref / literal) cs argument rparen
    store_str <- 'store'
    safe <- '_safe'
    """,
    store: [post_traverse: :store],
    store_str: [ignore: true],
    safe: [ignore: true]
  )

  def store(rest, [src, loc], context, _slot, _bytes) do
    {rest, [%Store{src: src, loc: loc}], context}
  end
end
