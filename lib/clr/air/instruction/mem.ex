defmodule Clr.Air.Instruction.Mem do
  require Pegasus

  alias Clr.Air
  require Air

  Air.import(~w[slotref cs lparen rparen type literal argument int]a)

  Pegasus.parser_from_string(
    """
    mem <- load / store / struct_field_val / set_union_tag
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

  defmodule StructFieldVal do
    defstruct [:src, :index]

    use Clr.Air.Instruction

    alias Clr.Block

    def analyze(%{src: {src_slot, _keep_or_clobber}, index: index}, dst_slot, analysis) do
      {{:struct, struct_types, _meta}, analysis} = Block.fetch_up!(analysis, src_slot)
      line_type = Enum.at(struct_types, index) || raise "unreachable"
      Block.put_type(analysis, dst_slot, line_type)
    end
  end

  Pegasus.parser_from_string(
    """
    struct_field_val <- struct_field_val_str lparen slotref cs int rparen
    struct_field_val_str <- 'struct_field_val'
    """,
    struct_field_val: [post_traverse: :struct_field_val],
    struct_field_val_str: [ignore: true]
  )

  def struct_field_val(rest, [index, src], context, _slot, _bytes) do
    {rest, [%StructFieldVal{src: src, index: index}], context}
  end

  defmodule SetUnionTag do
    defstruct [:src, :val]
  end

  Pegasus.parser_from_string(
    """
    set_union_tag <- set_union_tag_str lparen slotref cs literal rparen
    set_union_tag_str <- 'set_union_tag'
    """,
    set_union_tag: [post_traverse: :set_union_tag],
    set_union_tag_str: [ignore: true]
  )

  def set_union_tag(rest, [val, src], context, _slot, _bytes) do
    {rest, [%SetUnionTag{src: src, val: val}], context}
  end
end
