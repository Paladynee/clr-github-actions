defmodule Clr.Air.Instruction.Pointer do
  alias Clr.Air

  require Air
  require Pegasus

  Air.import(~w[argument cs slotref lparen rparen type lvalue literal int]a)

  Pegasus.parser_from_string(
    """
    pointer <- ptr_op / struct_field_ptr_index / struct_field_ptr / slice_len / slice_ptr /
      slice_elem_val / slice_elem_ptr / slice / array_elem_val / ptr_slice_len_ptr / ptr_slice_ptr_ptr /
      ptr_elem_val / ptr_elem_ptr / array_to_slice / error_return_trace / set_error_return_trace_index /
      set_error_return_trace / field_parent_ptr
    prefix <- 'ptr_'
    """,
    pointer: [export: true],
    prefix: [ignore: true]
  )

  # operations (ptr_add and ptr_sub)
  defmodule Op do
    defstruct [:op, :type, :src, :val]

    alias Clr.Type

    use Clr.Air.Instruction
    def slot_type(%{type: type}, _, block), do: {Type.from_air(type), block}
  end

  Pegasus.parser_from_string(
    """
    ptr_op <- prefix op lparen type cs (slotref / literal) cs argument rparen
    op <- add / sub
    add <- 'add'
    sub <- 'sub'
    """,
    ptr_op: [post_traverse: :ptr_op],
    add: [token: :add],
    sub: [token: :sub]
  )

  def ptr_op(rest, [val, src, type, op], context, _, _) do
    {rest, [%Op{op: op, val: val, src: src, type: type}], context}
  end

  defmodule StructFieldPtr do
    defstruct [:src, :index]
  end

  Pegasus.parser_from_string(
    """
    struct_field_ptr <- struct_field_ptr_str lparen slotref cs int rparen
    struct_field_ptr_str <- 'struct_field_ptr'
    """,
    struct_field_ptr: [post_traverse: :struct_field_ptr],
    struct_field_ptr_str: [ignore: true]
  )

  def struct_field_ptr(rest, [index, src], context, _loc, _bytes) do
    {rest, [%StructFieldPtr{src: src, index: index}], context}
  end

  defmodule StructFieldPtrIndex do
    defstruct [:type, :src, :index]
  end

  Pegasus.parser_from_string(
    """
    struct_field_ptr_index <- instruction int lparen type cs slotref rparen
    instruction <- 'struct_field_ptr_index_'
    """,
    struct_field_ptr_index: [post_traverse: :struct_field_ptr_index],
    instruction: [ignore: true]
  )

  def struct_field_ptr_index(
        rest,
        [op, type, index],
        context,
        _slot,
        _bytes
      ) do
    {rest, [%StructFieldPtrIndex{src: op, type: type, index: index}], context}
  end

  defmodule Slice do
    # Constructs a slice from a pointer and a length.
    # Uses the `ty_pl` field, payload is `Bin`. lhs is ptr, rhs is len.

    defstruct [:type, :src, :len]

    alias Clr.Type

    use Clr.Air.Instruction

    def slot_type(%{type: type}, _, block), do: {Type.from_air(type), block}
  end

  Pegasus.parser_from_string(
    """
    slice <- slice_str lparen type cs (slotref / literal) cs slotref rparen
    slice_str <- 'slice'
    """,
    slice: [post_traverse: :slice],
    slice_str: [ignore: true]
  )

  defp slice(rest, [len, src, type], context, _loc, _bytes) do
    {rest, [%Slice{type: type, src: src, len: len}], context}
  end

  # Given a slice value, return the length.
  # Result type is always usize.
  # Uses the `ty_op` field.
  Air.ty_op(:slice_len, SliceLen)

  # Given a slice value, return the pointer.
  # Uses the `ty_op` field.
  Air.ty_op(:slice_ptr, SlicePtr)

  # Given a pointer to a slice, return a pointer to the length of the slice.
  # Uses the `ty_op` field.
  Air.ty_op(:ptr_slice_len_ptr, PtrSliceLenPtr)

  # Given a pointer to a slice, return a pointer to the pointer of the slice.
  # Uses the `ty_op` field.
  Air.ty_op(:ptr_slice_ptr_ptr, PtrSlicePtrPtr)

  defmodule ArrayElemVal do
    # Given an (array value or vector value) and element index,
    # return the element value at that index.
    # Result type is the element type of the array operand.
    # Uses the `bin_op` field.
    defstruct [:src, :index_src]

    use Clr.Air.Instruction

    alias Clr.Block

    def slot_type(%{src: {src, _}}, _, block) do
      {{:array, type, _}, block} = Block.fetch_up!(block, src)
      {type, block}
    end
  end

  Pegasus.parser_from_string(
    """
    array_elem_val <- array_elem_val_str lparen argument cs argument rparen
    array_elem_val_str <- 'array_elem_val'
    """,
    array_elem_val: [post_traverse: :array_elem_val],
    array_elem_val_str: [ignore: true]
  )

  def array_elem_val(rest, [slot, type], context, _loc, _bytes) do
    {rest, [%ArrayElemVal{src: type, index_src: slot}], context}
  end

  defmodule SliceElemVal do
    # Given a slice value, and element index, return the element value at that index.
    # Result type is the element type of the slice operand.
    # Uses the `bin_op` field.
    defstruct [:src, :index_src]

    use Clr.Air.Instruction

    alias Clr.Block

    def slot_type(%{src: {src, _}}, _, block) do
      {{:ptr, :slice, type, _}, block} = Block.fetch_up!(block, src)
      {type, block}
    end
  end

  Pegasus.parser_from_string(
    """
    slice_elem_val <- slice_elem_val_str lparen slotref cs argument rparen
    slice_elem_val_str <- 'slice_elem_val'
    """,
    slice_elem_val: [post_traverse: :slice_elem_val],
    slice_elem_val_str: [ignore: true]
  )

  defp slice_elem_val(rest, [index, src], context, _loc, _bytes) do
    {rest, [%SliceElemVal{index_src: index, src: src}], context}
  end

  defmodule SliceElemPtr do
    # Given a slice value and element index, return a pointer to the element value at that index.
    # Result type is a pointer to the element type of the slice operand.
    # Uses the `ty_pl` field with payload `Bin`.
    defstruct [:type, :src, :index]

    use Clr.Air.Instruction

    def slot_type(_, _, _), do: raise("unimplemented")
  end

  Pegasus.parser_from_string(
    """
    slice_elem_ptr <- slice_elem_ptr_str lparen type cs slotref cs argument rparen
    slice_elem_ptr_str <- 'slice_elem_ptr'
    """,
    slice_elem_ptr: [post_traverse: :slice_elem_ptr],
    slice_elem_ptr_str: [ignore: true]
  )

  defp slice_elem_ptr(rest, [index, src, type], context, _loc, _bytes) do
    {rest, [%SliceElemPtr{index: index, src: src, type: type}], context}
  end

  defmodule PtrElemVal do
    # Given a pointer value, and element index, return the element value at that index.
    # Result type is the element type of the pointer operand.
    # Uses the `bin_op` field.
    defstruct [:src, :index_src]
  end

  Pegasus.parser_from_string(
    """
    ptr_elem_val <- ptr_elem_val_str lparen slotref cs argument rparen
    ptr_elem_val_str <- 'ptr_elem_val'
    """,
    ptr_elem_val: [post_traverse: :ptr_elem_val],
    ptr_elem_val_str: [ignore: true]
  )

  defp ptr_elem_val(rest, [index, src], context, _loc, _bytes) do
    {rest, [%PtrElemVal{index_src: index, src: src}], context}
  end

  defmodule PtrElemPtr do
    # Given a pointer value, and element index, return the element pointer at that index.
    # Result type is pointer to the element type of the pointer operand.
    # Uses the `ty_pl` field with payload `Bin`.
    defstruct [:loc, :val, :type]
  end

  Pegasus.parser_from_string(
    """
    ptr_elem_ptr <- ptr_elem_ptr_str lparen type cs (slotref / literal) cs argument rparen
    ptr_elem_ptr_str <- 'ptr_elem_ptr'
    """,
    ptr_elem_ptr: [post_traverse: :ptr_elem_ptr],
    ptr_elem_ptr_str: [ignore: true]
  )

  defp ptr_elem_ptr(rest, [val, loc, type], context, _loc, _byte) do
    {rest, [%PtrElemPtr{loc: loc, val: val, type: type}], context}
  end

  # Given a pointer to an array, return a slice.
  # Uses the `ty_op` field.
  Air.ty_op(:array_to_slice, ArrayToSlice)

  Air.unimplemented(:error_return_trace)

  Air.unimplemented(:set_error_return_trace)

  Air.unimplemented(:set_error_return_trace_index)

  defmodule FieldParentPtr do
    defstruct [:src, :index]
  end

  Pegasus.parser_from_string(
    """
    field_parent_ptr <- field_parent_ptr_str lparen slotref cs int rparen
    field_parent_ptr_str <- 'field_parent_ptr'
    """,
    field_parent_ptr: [post_traverse: :field_parent_ptr],
    field_parent_ptr_str: [ignore: true]
  )

  def field_parent_ptr(rest, [index, src], context, _loc, _bytes) do
    {rest, [%FieldParentPtr{src: src, index: index}], context}
  end
end
