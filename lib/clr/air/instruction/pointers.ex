defmodule Clr.Air.Instruction.Pointers do
  alias Clr.Air

  require Air
  require Pegasus

  Air.import(~w[argument cs slotref lparen rparen type lvalue literal int]a)

  Pegasus.parser_from_string(
    """
    pointers <- ptr_op / struct_field_ptr_index / struct_field_ptr / slice_len / slice_ptr /
      slice_elem_val / slice_elem_ptr / slice / array_elem_val / ptr_slice_len_ptr / ptr_slice_ptr_ptr /
      ptr_elem_val / ptr_elem_ptr / array_to_slice
    prefix <- 'ptr_'
    """,
    pointers: [export: true],
    prefix: [ignore: true]
  )

  # operations (ptr_add and ptr_sub)
  defmodule Op do
    defstruct [:op, :type, :src, :val]
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

  def struct_field_ptr(rest, [index, src], context, _slot, _bytes) do
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
    defstruct [:type, :src, :len]
  end

  Pegasus.parser_from_string(
    """
    slice <- slice_str lparen type cs (slotref / literal) cs slotref rparen
    slice_str <- 'slice'
    """,
    slice: [post_traverse: :slice],
    slice_str: [ignore: true]
  )

  defp slice(rest, [len, src, type], context, _slot, _bytes) do
    {rest, [%Slice{type: type, src: src, len: len}], context}
  end

  defmodule SliceLen do
    defstruct [:type, :src]
  end

  Air.ty_op(:slice_len, SliceLen)

  defmodule SlicePtr do
    defstruct [:type, :src]
  end

  Air.ty_op(:slice_ptr, SlicePtr)

  defmodule PtrSliceLenPtr do
    defstruct [:type, :src]
  end

  Air.ty_op(:ptr_slice_len_ptr, PtrSliceLenPtr)

  defmodule PtrSlicePtrPtr do
    defstruct [:type, :src]
  end

  Air.ty_op(:ptr_slice_ptr_ptr, PtrSlicePtrPtr)

  defmodule ArrayElemVal do
    defstruct [:src, :index_src]
  end

  Pegasus.parser_from_string(
    """
    array_elem_val <- array_elem_val_str lparen argument cs argument rparen
    array_elem_val_str <- 'array_elem_val'
    """,
    array_elem_val: [post_traverse: :array_elem_val],
    array_elem_val_str: [ignore: true]
  )

  def array_elem_val(rest, [slot, type], context, _slot, _bytes) do
    {rest, [%ArrayElemVal{src: type, index_src: slot}], context}
  end

  defmodule SliceElemVal do
    defstruct [:src, :index_src]
  end

  Pegasus.parser_from_string(
    """
    slice_elem_val <- slice_elem_val_str lparen slotref cs argument rparen
    slice_elem_val_str <- 'slice_elem_val'
    """,
    slice_elem_val: [post_traverse: :slice_elem_val],
    slice_elem_val_str: [ignore: true]
  )

  defp slice_elem_val(rest, [index, src], context, _slot, _bytes) do
    {rest, [%SliceElemVal{index_src: index, src: src}], context}
  end

  defmodule SliceElemPtr do
    defstruct [:type, :src, :index]
  end

  Pegasus.parser_from_string(
    """
    slice_elem_ptr <- slice_elem_ptr_str lparen type cs slotref cs argument rparen
    slice_elem_ptr_str <- 'slice_elem_ptr'
    """,
    slice_elem_ptr: [post_traverse: :slice_elem_ptr],
    slice_elem_ptr_str: [ignore: true]
  )

  defp slice_elem_ptr(rest, [index, src, type], context, _slot, _bytes) do
    {rest, [%SliceElemPtr{index: index, src: src, type: type}], context}
  end

  defmodule PtrElemVal do
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

  defp ptr_elem_val(rest, [index, src], context, _slot, _bytes) do
    {rest, [%PtrElemVal{index_src: index, src: src}], context}
  end

  defmodule PtrElemPtr do
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

  defp ptr_elem_ptr(rest, [val, loc, type], context, _slot, _byte) do
    {rest, [%PtrElemPtr{loc: loc, val: val, type: type}], context}
  end

  defmodule ArrayToSlice do
    defstruct [:type, :src]
  end

  Air.ty_op(:array_to_slice, ArrayToSlice)
end
