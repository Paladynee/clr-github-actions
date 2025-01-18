defmodule Clr.Air.Instruction.Casts do
  alias Clr.Air

  require Pegasus
  require Air

  Pegasus.parser_from_string(
    """
    casts <- bitcast / int_from_ptr / int_from_bool / intcast / trunc /
      optional_payload_ptr_set / optional_payload_ptr / optional_payload /
      wrap_optional / unwrap_errunion_payload_ptr / unwrap_errunion_payload / 
      unwrap_errunion_err_ptr / unwrap_errunion_err / errunion_payload_ptr_set /
      wrap_errunion_err / wrap_errunion_payload
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

  defmodule Intcast do
    defstruct [:type, :src]
  end

  Air.ty_op(:intcast, Intcast)

  defmodule Trunc do
    defstruct [:type, :src]
  end

  Air.ty_op(:trunc, Trunc)

  defmodule OptionalPayload do
    defstruct [:type, :src]
  end

  Air.ty_op(:optional_payload, OptionalPayload)

  defmodule OptionalPayloadPtr do
    defstruct [:type, :src]
  end

  Air.ty_op(:optional_payload_ptr, OptionalPayloadPtr)

  defmodule OptionalPayloadPtrSet do
    defstruct [:type, :src]
  end

  Air.ty_op(:optional_payload_ptr_set, OptionalPayloadPtrSet)

  defmodule WrapOptional do
    defstruct [:type, :src]
  end

  Air.ty_op(:wrap_optional, WrapOptional)

  defmodule UnwrapErrunionPayload do
    defstruct [:type, :src]
  end

  Air.ty_op(:unwrap_errunion_payload, UnwrapErrunionPayload)

  defmodule UnwrapErrunionErr do
    defstruct [:type, :src]
  end

  Air.ty_op(:unwrap_errunion_err, UnwrapErrunionErr)

  defmodule UnwrapErrunionPayloadPtr do
    defstruct [:type, :src]
  end

  Air.ty_op(:unwrap_errunion_payload_ptr, UnwrapErrunionPayloadPtr)

  defmodule UnwrapErrunionErrPtr do
    defstruct [:type, :src]
  end

  Air.ty_op(:unwrap_errunion_err_ptr, UnwrapErrunionErrPtr)

  defmodule ErrunionPayloadPtrSet do
    defstruct [:type, :src]
  end

  Air.ty_op(:errunion_payload_ptr_set, ErrunionPayloadPtrSet)

  defmodule WrapErrunionPayload do
    defstruct [:type, :src]
  end

  Air.ty_op(:wrap_errunion_payload, WrapErrunionPayload)

  defmodule WrapErrunionErr do
    defstruct [:type, :src]
  end

  Air.ty_op(:wrap_errunion_err, WrapErrunionErr)
end
