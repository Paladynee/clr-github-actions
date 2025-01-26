defmodule Clr.Air.Instruction.Dbg do
  require Pegasus

  alias Clr.Air

  require Air

  Air.import(
    ~w[rparen lparen int colon type cs codeblock clobbers space fn_literal literal slotref dquoted argument]a
  )

  Pegasus.parser_from_string(
    """
    dbg <- trap / dbg_stmt / dbg_empty_stmt / dbg_inline_block / dbg_var_ptr / dbg_var_val / dbg_arg_inline / breakpoint
    """,
    dbg: [export: true]
  )

  # Lowers to a trap/jam instruction causing program abortion.
  # This may lower to an instruction known to be invalid.
  # Sometimes, for the lack of a better instruction, `trap` and `breakpoint` may compile down to the same code.
  # Result type is always noreturn; no instructions in a block follow this one.
  Air.noreturn(:trap, Trap)

  defmodule Stmt do
    # Notes the beginning of a source code statement and marks the line and column.
    # Result type is always void.
    # Uses the `dbg_stmt` field.

    defstruct [:loc]

    use Clr.Air.Instruction

    def slot_type(_, _, block), do: {:void, block}

    def analyze(%{loc: loc}, _slot, block, _config), do: {:halt, %{block | loc: loc}}
  end

  Pegasus.parser_from_string(
    """
    dbg_stmt <- dbg_stmt_str lparen intrange rparen

    dbg_stmt_str <- 'dbg_stmt'

    intrange <- int colon int
    """,
    dbg_stmt: [post_traverse: :dbg_stmt],
    dbg_stmt_str: [ignore: true]
  )

  defp dbg_stmt(rest, [col, row], context, _loc, _bytes) do
    {rest, [%Stmt{loc: {row, col}}], context}
  end

  defmodule EmptyStmt do
    # Marks a statement that can be stepped to but produces no code.

    defstruct []

    use Clr.Air.Instruction

    def slot_type(_, _, block), do: {:void, block}
  end

  Pegasus.parser_from_string(
    """
    dbg_empty_stmt <- dbg_empty_stmt_str
    dbg_empty_stmt_str <- 'dbg_empty_stmt()'
    """,
    dbg_empty_stmt: [post_traverse: :dbg_empty_stmt],
    dbg_empty_stmt_str: [ignore: true]
  )

  def dbg_empty_stmt(rest, [], context, _, _) do
    {rest, [%EmptyStmt{}], context}
  end

  defmodule InlineBlock do
    # A block that represents an inlined function call.
    # Uses the `ty_pl` field. Payload is `DbgInlineBlock`.

    defstruct [:type, :what, :code, clobbers: []]
  end

  Pegasus.parser_from_string(
    """
    dbg_inline_block <- dbg_inline_block_str lparen type cs fn_literal cs codeblock (space clobbers)? rparen
    dbg_inline_block_str <- 'dbg_inline_block'
    """,
    dbg_inline_block: [post_traverse: :dbg_inline_block],
    dbg_inline_block_str: [ignore: true]
  )

  defp dbg_inline_block(rest, [codeblock, fun, name], context, _loc, _bytes) do
    {rest, [%InlineBlock{code: codeblock, what: fun, type: name}], context}
  end

  defp dbg_inline_block(
         rest,
         [{:clobbers, clobbers}, codeblock, fun, name],
         context,
         _slot,
         _bytes
       ) do
    {rest, [%InlineBlock{code: codeblock, what: fun, type: name, clobbers: clobbers}], context}
  end

  defmodule VarPtr do
    # Marks the beginning of a local variable. The operand is a pointer pointing
    # to the storage for the variable. The local may be a const or a var.
    # Result type is always void.
    # Uses `pl_op`. The payload index is the variable name. It points to the extra
    # array, reinterpreting the bytes there as a null-terminated string.

    defstruct [:slot, :name]

    use Clr.Air.Instruction

    def slot_type(_, _, block), do: {:void, block}
  end

  Pegasus.parser_from_string(
    """
    dbg_var_ptr <- dbg_var_ptr_str lparen (slotref / literal) cs dquoted rparen
    dbg_var_ptr_str <- 'dbg_var_ptr'
    """,
    dbg_var_ptr: [post_traverse: :dbg_var_ptr],
    dbg_var_ptr_str: [ignore: true]
  )

  def dbg_var_ptr(rest, [name, slot], context, _loc, _bytes) do
    {rest, [%VarPtr{name: name, slot: slot}], context}
  end

  defmodule VarVal do
    # Same as `dbg_var_ptr` except the local is a const, not a var, and the
    # operand is the local's value.

    defstruct [:slot, :name]

    use Clr.Air.Instruction

    def slot_type(_, _, block), do: {:void, block}
  end

  Pegasus.parser_from_string(
    """
    dbg_var_val <- dbg_var_val_str lparen argument cs dquoted rparen
    dbg_var_val_str <- 'dbg_var_val' 
    """,
    dbg_var_val: [post_traverse: :dbg_var_val],
    dbg_var_val_str: [ignore: true]
  )

  def dbg_var_val(rest, [name, slot], context, _loc, _bytes) do
    {rest, [%VarVal{name: name, slot: slot}], context}
  end

  defmodule ArgInline do
    # Same as `dbg_var_val` except the local is an inline function argument.
    defstruct [:arg, :name]

    use Clr.Air.Instruction

    def slot_type(_, _, block), do: {:void, block}
  end

  Pegasus.parser_from_string(
    """
    dbg_arg_inline <- dbg_arg_inline_str lparen argument cs dquoted rparen
    dbg_arg_inline_str <- 'dbg_arg_inline'
    """,
    dbg_arg_inline: [export: true, post_traverse: :dbg_arg_inline],
    dbg_arg_inline_str: [ignore: true]
  )

  def dbg_arg_inline(rest, [name, slot], context, _loc, _bytes) do
    {rest, [%ArgInline{name: name, arg: slot}], context}
  end

  Air.unimplemented(:breakpoint)
end
