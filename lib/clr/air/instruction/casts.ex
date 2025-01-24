defmodule Clr.Air.Instruction.Casts do
  alias Clr.Air
  alias Clr.Block
  alias Clr.Type

  require Pegasus
  require Air

  Pegasus.parser_from_string(
    """
    casts <- bitcast / int_from_ptr / int_from_bool / intcast / trunc /
      optional_payload_ptr_set / optional_payload_ptr / optional_payload /
      wrap_optional / unwrap_errunion_payload_ptr / unwrap_errunion_payload / 
      unwrap_errunion_err_ptr / unwrap_errunion_err / errunion_payload_ptr_set /
      wrap_errunion_err / wrap_errunion_payload / int_from_float / float_from_int /
      addrspace_cast / fpext / fptrunc
    """,
    casts: [export: true]
  )

  Air.import(~w[argument lvalue type slotref cs lparen rparen literal]a)

  # Reinterpret the memory representation of a value as a different type.
  # Uses the `ty_op` field.
  Air.ty_op(:bitcast, Bitcast)

  # Converts a pointer to its address. Result type is always `usize`.
  # Pointer type size may be any, including slice.
  # Uses the `un_op` field.
  Air.un_op(:int_from_ptr, IntFromPtr)

  # Given a boolean, returns 0 or 1.
  # Result type is always `u1`.
  # Uses the `un_op` field.
  Air.un_op(:int_from_bool, IntFromBool)

  # Returns an integer with a different type than the operand. The new type may have
  # fewer, the same, or more bits than the operand type. The new type may also
  # differ in signedness from the operand type. However, the instruction
  # guarantees that the same integer value fits in both types.
  # The new type may also be an enum type, in which case the integer cast operates on
  # the integer tag type of the enum.
  # See `trunc` for integer truncation.
  # Uses the `ty_op` field.
  Air.ty_op(:intcast, Intcast)

  # Truncate higher bits from an integer, resulting in an integer with the same
  # sign but an equal or smaller number of bits.
  # Uses the `ty_op` field.
  Air.ty_op(:trunc, Trunc)

  # ?T => T. If the value is null, undefined behavior.
  # Uses the `ty_op` field.
  Air.ty_op(:optional_payload, OptionalPayload)

  # *?T => *T. If the value is null, undefined behavior.
  # Uses the `ty_op` field.
  Air.ty_op(:optional_payload_ptr, OptionalPayloadPtr)

  # *?T => *T. Sets the value to non-null with an undefined payload value.
  # Uses the `ty_op` field.
  Air.ty_op(:optional_payload_ptr_set, OptionalPayloadPtrSet)

  # Given a payload value, wraps it in an optional type.
  # Uses the `ty_op` field.
  Air.ty_op(:wrap_optional, WrapOptional)

  # E!T -> T. If the value is an error, undefined behavior.
  # Uses the `ty_op` field
  Air.ty_op(:unwrap_errunion_payload, UnwrapErrunionPayload)

  # E!T -> E. If the value is not an error, undefined behavior.
  # Uses the `ty_op` field.
  Air.ty_op(:unwrap_errunion_err, UnwrapErrunionErr)

  # *(E!T) -> *T. If the value is an error, undefined behavior.
  # Uses the `ty_op` field.
  Air.ty_op(:unwrap_errunion_payload_ptr, UnwrapErrunionPayloadPtr)

  # *(E!T) -> E. If the value is not an error, undefined behavior.
  # Uses the `ty_op` field.
  Air.ty_op(:unwrap_errunion_err_ptr, UnwrapErrunionErrPtr)

  # *(E!T) => *T. Sets the value to non-error with an undefined payload value.
  # Uses the `ty_op` field.
  Air.ty_op(:errunion_payload_ptr_set, ErrunionPayloadPtrSet)

  # wrap from T to E!T
  # Uses the `ty_op` field.
  Air.ty_op(:wrap_errunion_payload, WrapErrunionPayload) do
    def slot_type(%{type: {:errorable, errors, _}, src: {slot, _}}, block) when is_integer(slot) do
      {type, block} = Block.fetch_up!(block, slot) 
      {{:errorable, errors, type, %{}}, block}
    end
  end

  # wrap from E to E!T
  # Uses the `ty_op` field.
  Air.ty_op :wrap_errunion_err, WrapErrunionErr do
    def slot_type(%{type: type}, block) do
      {Type.from_air(type), block}
    end
  end

  defmodule IntFromFloat do
    # Given a float operand, return the integer with the closest mathematical meaning.
    # Uses the `ty_op` field.
    defstruct [:type, :src, optimized: false]

    use Clr.Air.Instruction
    Clr.Air.Instruction.default_slot_type_function(:ty_op)
  end

  Pegasus.parser_from_string(
    """
    int_from_float <- int_from_float_str optimized? lparen type cs argument rparen
    int_from_float_str <- 'int_from_float'
    optimized <- '_optimized'
    """,
    int_from_float: [post_traverse: :int_from_float],
    int_from_float_str: [ignore: true],
    optimized: [token: :optimized]
  )

  def int_from_float(rest, [src, type | rest_args], context, _loc, _bytes) do
    optimized =
      case rest_args do
        [] -> false
        [:optimized] -> true
      end

    {rest, [%IntFromFloat{src: src, type: type, optimized: optimized}], context}
  end

  # Given an integer operand, return the float with the closest mathematical meaning.
  # Uses the `ty_op` field.
  Air.ty_op(:float_from_int, FloatFromInt)

  # Convert from a float type to a wider one.
  # Uses the `ty_op` field.
  Air.ty_op(:fpext, Fpext)

  # Convert from a float type to a smaller one.
  # Uses the `ty_op` field.
  Air.ty_op(:fptrunc, Fptrunc)

  Air.unimplemented(:addrspace_cast)
end
