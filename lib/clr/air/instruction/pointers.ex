defmodule Clr.Air.Instruction.Pointers do
  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[argument cs slotref lparen rparen type lvalue literal]a)

  Pegasus.parser_from_string(
    """
    pointers <- ptr_op
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
end
