defmodule Clr.Air.Instruction.Pointers do
  alias Clr.Air 
  
  require Air
  require Pegasus

  Air.import(~w[argument cs slotref lparen rparen type lvalue literal int]a)

  Pegasus.parser_from_string(
    """
    pointers <- ptr_op / struct_field_ptr_index / struct_field_ptr / slice_len / slice_ptr /
      slice
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
end
