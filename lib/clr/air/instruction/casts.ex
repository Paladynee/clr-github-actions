defmodule Clr.Air.Instruction.Casts do
  require Pegasus
  require Clr.Air

  Pegasus.parser_from_string(
    """
    casts <- bitcast / int_from_ptr / int_from_bool
    """,
    casts: [export: true]
  )

  defmodule Bitcast do
    defstruct [:type, :src]

    use Clr.Air.Instruction
    alias Clr.Block

    def analyze(%{src: {src_slot, _}}, dst_slot, block) do
      case Block.fetch_up!(block, src_slot) do
        {type, block} ->
          Block.put_type(block, dst_slot, type)
      end
    end
  end

  Clr.Air.import(~w[argument lvalue type slotref cs lparen rparen literal]a)

  Pegasus.parser_from_string(
    """
    bitcast <- bitcast_str lparen type cs argument rparen
    bitcast_str <- 'bitcast'
    """,
    bitcast: [post_traverse: :bitcast],
    bitcast_str: [ignore: true]
  )

  def bitcast(rest, [slot, type], context, _slot, _bytes) do
    {rest, [%Bitcast{type: type, src: slot}], context}
  end

  defmodule IntFromPtr do
    defstruct [:val]
  end

  Pegasus.parser_from_string(
    """
    int_from_ptr <- int_from_ptr_str lparen (literal / slotref) rparen
    int_from_ptr_str <- 'int_from_ptr'
    """,
    int_from_ptr: [post_traverse: :int_from_ptr],
    int_from_ptr_str: [ignore: true]
  )

  def int_from_ptr(rest, [value], context, _slot, _bytes) do
    {rest, [%IntFromPtr{val: value}], context}
  end

  defmodule IntFromBool do
    defstruct [:val]
  end

  Pegasus.parser_from_string(
    """
    int_from_bool <- int_from_bool_str lparen (literal / slotref) rparen
    int_from_bool_str <- 'int_from_bool'
    """,
    int_from_bool: [post_traverse: :int_from_bool],
    int_from_bool_str: [ignore: true]
  )

  def int_from_bool(rest, [value], context, _slot, _bytes) do
    {rest, [%IntFromBool{val: value}], context}
  end
end
