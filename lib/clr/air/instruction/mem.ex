defmodule Clr.Air.Instruction.Mem do
  require Pegasus

  alias Clr.Air
  alias Clr.Block
  alias Clr.Type

  require Air

  Air.import(
    ~w[slotref cs lparen rparen type literal argument int lvalue enum_value space rbrace lbrace rbrack lbrack]a
  )

  Pegasus.parser_from_string(
    """
    mem <- alloc / load / store / struct_field_val / set_union_tag / get_union_tag / memset / memcpy / 
      tag_name / error_name / aggregate_init / union_init / prefetch
    safe <- '_safe'
    """,
    mem: [export: true],
    safe: [token: :safe]
  )

  defmodule Alloc do
    # Allocates stack local memory.
    # Uses the `ty` field.
    defstruct [:type]

    use Clr.Air.Instruction

    def slot_type(%Alloc{type: type}, _, block), do: {Type.from_air(type), block}
  end

  Pegasus.parser_from_string(
    """
    alloc <- alloc_str lparen type rparen
    alloc_str <- 'alloc'
    """,
    alloc: [post_traverse: :alloc],
    alloc_str: [ignore: true]
  )

  def alloc(rest, [type], context, _loc, _bytes) do
    {rest, [%Alloc{type: type}], context}
  end

  Air.ty_op :load, Load do
    require Type

    def slot_type(%{src: {slot, _}}, _, block) when is_integer(slot) do
      {{:ptr, :one, type, _}, block} = Block.fetch_up!(block, slot)
      {type, block}
    end

    def slot_type(%{type: type}, _, block), do: {Type.from_air(type), block}
  end

  defmodule Store do
    defstruct [:dst, :src, :safe]

    use Clr.Air.Instruction

    def slot_type(_type, _, block), do: {:void, block}

    def analyze(%{dst: {dst_slot, _}, src: {src_slot, _}}, _src_slot, block, _config)
        when is_integer(src_slot) do
      {src_type, block} = Block.fetch_up!(block, src_slot)

      new_block =
        Block.update_type!(block, dst_slot, fn
          {:ptr, :one, child, ptr_meta} ->
            {:ptr, :one, Type.put_meta(child, Type.get_meta(src_type)), ptr_meta}
        end)

      {:cont, new_block}
    end

    def analyze(_instruction, _slot, block, _config), do: {:cont, block}
  end

  Pegasus.parser_from_string(
    """
    store <- store_str safe? lparen (slotref / literal) cs argument rparen
    store_str <- 'store'
    """,
    store: [post_traverse: :store],
    store_str: [ignore: true]
  )

  def store(rest, [src, dst | rest_args], context, _loc, _bytes) do
    safe =
      case rest_args do
        [] -> false
        [:safe] -> true
      end

    {rest, [%Store{src: src, dst: dst, safe: safe}], context}
  end

  defmodule StructFieldVal do
    defstruct [:src, :index]

    use Clr.Air.Instruction

    alias Clr.Block

    def slot_type(%{src: {slot, _}, index: index}, _, block) do
      {{:struct, list, _}, block} = Block.fetch_up!(block, slot)

      if type = Enum.at(list, index) do
        {type, block}
      else
        raise "unreachable"
      end
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

  def struct_field_val(rest, [index, src], context, _loc, _bytes) do
    {rest, [%StructFieldVal{src: src, index: index}], context}
  end

  defmodule SetUnionTag do
    # Given a pointer to a tagged union, set its tag to the provided value.
    # Result type is always void.
    # Uses the `bin_op` field. LHS is union pointer, RHS is new tag value.
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

  def set_union_tag(rest, [val, src], context, _loc, _bytes) do
    {rest, [%SetUnionTag{src: src, val: val}], context}
  end

  # Given a tagged union value, get its tag value.
  # Uses the `ty_op` field.
  Air.ty_op(:get_union_tag, GetUnionTag)

  defmodule Set do
    # Given dest pointer and value, set all elements at dest to value.
    # Dest pointer is either a slice or a pointer to array.
    # The element type may be any type, and the slice may have any alignment.
    # Result type is always void.
    # Uses the `bin_op` field. LHS is the dest slice. RHS is the element value.
    # The element value may be undefined, in which case the destination
    # memory region has undefined bytes after this instruction is
    # evaluated. In such case ignoring this instruction is legal
    # lowering.
    # If the length is compile-time known (due to the destination being a
    # pointer-to-array), then it is guaranteed to be greater than zero.
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

  def memset(rest, [val, src | rest_args], context, _loc, _bytes) do
    safe =
      case rest_args do
        [] -> false
        [:safe] -> true
      end

    {rest, [%Set{src: src, val: val, safe: safe}], context}
  end

  defmodule Cpy do
    # Given dest pointer and source pointer, copy elements from source to dest.
    # Dest pointer is either a slice or a pointer to array.
    # The dest element type may be any type.
    # Source pointer must have same element type as dest element type.
    # Dest slice may have any alignment; source pointer may have any alignment.
    # The two memory regions must not overlap.
    # Result type is always void.
    # Uses the `bin_op` field. LHS is the dest slice. RHS is the source pointer.
    # If the length is compile-time known (due to the destination or
    # source being a pointer-to-array), then it is guaranteed to be
    # greater than ze
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

  def memcpy(rest, [val, loc], context, _loc, _bytes) do
    {rest, [%Cpy{loc: loc, val: val}], context}
  end

  # Given an enum tag value, returns the tag name. The enum type may be non-exhaustive.
  # Result type is always `[:0]const u8`.
  # Uses the `un_op` field
  Air.un_op(:tag_name, TagName, :str)

  # Given an error value, return the error name. Result type is always `[:0]const u8`.
  # Uses the `un_op` field.
  Air.un_op(:error_name, ErrorName, :str)

  defmodule AggregateInit do
    # Constructs a vector, tuple, struct, or array value out of runtime-known elements.
    # Some of the elements may be comptime-known.
    # Uses the `ty_pl` field, payload is index of an array of elements, each of which
    # is a `Ref`. Length of the array is given by the vector type.
    # If the type is an array with a sentinel, the AIR elements do not include it
    # explicitly.
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

  defp aggregate_init(rest, [params, init], context, _loc, _bytes) do
    {rest, [%AggregateInit{params: params, init: init}], context}
  end

  defp struct_init(rest, params, context, _loc, _bytes) do
    {rest, [Enum.reverse(params)], context}
  end

  defp initializer(rest, [val, "=", type], context, _loc, _bytes) do
    {rest, [{type, val}], context}
  end

  defp initializer(rest, [type], context, _loc, _bytes) do
    {rest, [type], context}
  end

  defp params(rest, params, context, _loc, _bytes) do
    {rest, [Enum.reverse(params)], context}
  end

  defmodule UnionInit do
    # Constructs a union from a field index and a runtime-known init value.
    # Uses the `ty_pl` field with payload `UnionIni
    defstruct [:index, :src]
  end

  Pegasus.parser_from_string(
    """
    union_init <- union_init_str lparen int cs argument rparen
    union_init_str <- 'union_init'
    """,
    union_init: [post_traverse: :union_init],
    union_init_str: [ignore: true]
  )

  def union_init(rest, [src, index], context, _loc, _bytes) do
    {rest, [%UnionInit{src: src, index: index}], context}
  end

  defmodule Prefetch do
    # Communicates an intent to load memory.
    # Result is always unused.
    # Uses the `prefetch` field.
    defstruct [:src, :rw, :locality, :cache]
  end

  Pegasus.parser_from_string(
    """
    prefetch <- prefetch_str lparen argument cs rw cs int cs cache rparen
    prefetch_str <- 'prefetch'
    rw <- read / write
    cache <- instruction / data
    read <- 'read'
    write <- 'write'
    instruction <- 'instruction'
    data <- 'data'
    """,
    prefetch: [post_traverse: :prefetch],
    prefetch_str: [ignore: true],
    read: [token: :read],
    write: [token: :write],
    instruction: [token: :instruction],
    data: [token: :data]
  )

  def prefetch(rest, [cache, locality, rw, src], context, _loc, _bytes) do
    {rest, [%Prefetch{src: src, rw: rw, locality: locality, cache: cache}], context}
  end
end
