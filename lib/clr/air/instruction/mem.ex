defmodule Clr.Air.Instruction.Mem do
  require Pegasus

  alias Clr.Air
  require Air

  Air.import(~w[slotref cs lparen rparen type literal argument int lvalue]a)

  Pegasus.parser_from_string(
    """
    mem <- alloc / load / store / struct_field_val / set_union_tag / memset / tag_name / error_name
    safe <- '_safe'
    """,
    mem: [export: true],
    safe: [token: :safe]
  )

  defmodule Alloc do
    defstruct [:type]

    use Clr.Air.Instruction

    alias Clr.Block
    alias Clr.Type

    def analyze(%{type: {:ptr, _, _, _} = type}, slot, analysis) do
      Block.put_type(analysis, slot, Type.from_air(type), stack: analysis.function)
    end
  end

  Pegasus.parser_from_string(
    """
    alloc <- alloc_str lparen type rparen
    alloc_str <- 'alloc'
    """,
    alloc: [post_traverse: :alloc],
    alloc_str: [ignore: true]
  )

  def alloc(rest, [type], context, _slot, _bytes) do
    {rest, [%Alloc{type: type}], context}
  end

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
    defstruct [:loc, :src, :safe]
  end

  Pegasus.parser_from_string(
    """
    store <- store_str safe? lparen (slotref / literal) cs argument rparen
    store_str <- 'store'
    """,
    store: [post_traverse: :store],
    store_str: [ignore: true]
  )

  def store(rest, [src, loc | rest_args], context, _slot, _bytes) do
    safe =
      case rest_args do
        [] -> false
        [:safe] -> true
      end

    {rest, [%Store{src: src, loc: loc, safe: safe}], context}
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

  defmodule Memset do
    defstruct [:src, :val, :safe]
  end

  Pegasus.parser_from_string(
    """
    memset <- memset_str safe? lparen (lvalue / slotref) cs lvalue rparen
    memset_str <- 'memset'
    """,
    memset: [post_traverse: :memset],
    memset_str: [ignore: true]
  )

  def memset(rest, [val, src | rest_args], context, _slot, _bytes) do
    safe =
      case rest_args do
        [] -> false
        [:safe] -> true
      end

    {rest, [%Memset{src: src, val: val, safe: safe}], context}
  end

  defmodule TagName do
    defstruct [:src]
  end

  Air.un_op(:tag_name, TagName)

  defmodule ErrorName do
    defstruct [:src]
  end

  Air.un_op(:error_name, ErrorName)
end
