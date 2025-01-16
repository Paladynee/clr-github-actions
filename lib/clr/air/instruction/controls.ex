defmodule Clr.Air.Instruction.Controls do
  require Pegasus
  require Clr.Air

  Clr.Air.import(
    ~w[argument cs slotref lparen rparen type lvalue literal clobbers space codeblock]a
  )

  Pegasus.parser_from_string(
    """
    controls <- return / block / loop / repeat / br
    """,
    controls: [export: true]
  )

  # returns

  Pegasus.parser_from_string(
    """
    return <- ret_ptr
    ret_ptr <- 'ret_ptr' lparen type rparen
    """,
    ret_ptr: [export: true, post_traverse: :ret_ptr]
  )

  defmodule RetPtr do
    defstruct [:type]
  end

  def ret_ptr(rest, [value, "ret_ptr"], context, _slot, _bytes) do
    {rest, [%RetPtr{type: value}], context}
  end

  defmodule Block do
    defstruct [:type, :code, clobbers: []]
  end

  Pegasus.parser_from_string(
    """
    block <- block_str lparen type cs codeblock (space clobbers)? rparen
    block_str <- 'block'
    """,
    block: [post_traverse: :block],
    block_str: [ignore: true]
  )

  def block(rest, [codeblock, type], context, _slot, _bytes) do
    {rest, [%Block{type: type, code: codeblock}], context}
  end

  def block(rest, [{:clobbers, clobbers}, codeblock, type], context, _slot, _bytes) do
    {rest, [%Block{type: type, code: codeblock, clobbers: clobbers}], context}
  end

  defmodule Loop do
    defstruct [:type, :code]
  end

  Pegasus.parser_from_string(
    """
    loop <- loop_str lparen type cs codeblock rparen
    loop_str <- 'loop'
    """,
    loop: [post_traverse: :loop],
    loop_str: [ignore: true]
  )

  def loop(rest, [codeblock, type], context, _slot, _bytes) do
    {rest, [%Loop{type: type, code: codeblock}], context}
  end

  defmodule Repeat do
    defstruct [:goto]
  end

  Pegasus.parser_from_string("""
    repeat <- repeat_str lparen slotref rparen
    repeat_str <- 'repeat'
    """,
    repeat: [post_traverse: :repeat],
    repeat_str: [ignore: true]
  )

  def repeat(rest, [goto], context, _slot, _bytes) do
    {rest, [%Repeat{goto: goto}], context}
  end

  defmodule Br do
    defstruct [:goto, :value]
  end

  Pegasus.parser_from_string(
    """
    br <- br_str lparen slotref cs argument rparen
    br_str <- 'br'
    """,
    br: [post_traverse: :br],
    br_str: [ignore: true]
  )

  def br(rest, [value, goto], context, _, _) do
    {rest, [%Br{goto: goto, value: value}], context}
  end

end
