defmodule Clr.Air.Instruction.Mem do
  require Pegasus

  alias Clr.Air
  require Air

  Air.import(
    ~w[slotref cs lparen rparen type literal argument int lvalue enum_value space rbrace lbrace rbrack lbrack]a
  )

  Pegasus.parser_from_string(
    """
    mem <- alloc / load / store / struct_field_val / set_union_tag / memset / memcpy / tag_name / error_name / aggregate_init
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

  Air.ty_op :load, Load do
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

  defmodule Set do
    defstruct [:src, :val, :safe]
  end

  Pegasus.parser_from_string(
    """
    memset <- memset_str safe? lparen argument cs argument rparen
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

    {rest, [%Set{src: src, val: val, safe: safe}], context}
  end

  defmodule Cpy do
    defstruct [:loc, :val]
  end

  Pegasus.parser_from_string(
    """
    memcpy <- memcpy_str lparen argument cs argument rparen
    memcpy_str <- 'memcpy'
    """,
    memcpy: [post_traverse: :memcpy],
    memcpy_str: [ignore: true]
  )

  def memcpy(rest, [val, loc], context, _slot, _bytes) do
    {rest, [%Cpy{loc: loc, val: val}], context}
  end

  Air.un_op(:tag_name, TagName)

  Air.un_op(:error_name, ErrorName)

  defmodule AggregateInit do
    defstruct [:init, :params]
  end

  Pegasus.parser_from_string(
    """
    aggregate_init <- aggregate_init_str lparen (struct_init / lvalue / type) cs params rparen

    struct_init <- struct_str space lbrace space initializer (cs initializer)* space rbrace 

    initializer <- assigned_type / type
    assigned_type <- type space '=' space value
    value <- lvalue / int / enum_value

    aggregate_init_str <- 'aggregate_init'
    struct_str <- 'struct'

    params <- lbrack argument (cs argument)* rbrack
    """,
    aggregate_init: [post_traverse: :aggregate_init],
    struct_init: [post_traverse: :struct_init],
    initializer: [post_traverse: :initializer],
    aggregate_init_str: [ignore: true],
    struct_str: [ignore: true],
    params: [post_traverse: :params]
  )

  defp aggregate_init(rest, [params, init], context, _slot, _bytes) do
    {rest, [%AggregateInit{params: params, init: init}], context}
  end

  defp struct_init(rest, params, context, _slot, _bytes) do
    {rest, [Enum.reverse(params)], context}
  end

  defp initializer(rest, [val, "=", type], context, _slot, _bytes) do
    {rest, [{type, val}], context}
  end

  defp initializer(rest, [type], context, _slot, _bytes) do
    {rest, [type], context}
  end

  defp params(rest, params, context, _slot, _bytes) do
    {rest, [Enum.reverse(params)], context}
  end
end
