defmodule Clr.Air.Instruction.Casts do
  alias Clr.Air

  require Pegasus
  require Air

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

  Air.import(~w[argument lvalue type slotref cs lparen rparen literal]a)

  defmodule Bitcast do
    defstruct [:type, :src]
  end

  Air.ty_op(:bitcast, Bitcast)

  defmodule IntFromPtr do
    defstruct [:src]
  end

  Air.un_op(:int_from_ptr, IntFromPtr)

  defmodule IntFromBool do
    defstruct [:src]
  end

  Air.un_op(:int_from_bool, IntFromBool)
end
