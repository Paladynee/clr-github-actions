defmodule ClrTest.AirParsers.VectorTests do
  use ExUnit.Case, async: true

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction

  alias Clr.Air.Instruction.Vector.Reduce

  test "reduce" do
    assert %Reduce{src: {0, :keep}, op: :or} =
             Instruction.parse("reduce(%0, Or)")
  end

  test "reduce_optimized" do
    assert %Reduce{src: {0, :keep}, op: :or, optimized: true} =
             Instruction.parse("reduce_optimized(%0, Or)")
  end

  alias Clr.Air.Instruction.Vector.Cmp

  test "cmp_vector" do
    assert %Cmp{
             op: :neq,
             lhs: {405, :clobber},
             rhs: {:literal, {:lvalue, [{:vector, {:lvalue, ["u8"]}, 16}]}, _}
           } =
             Instruction.parse(
               "cmp_vector(neq, %405!, <@Vector(16, u8), .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }>)"
             )
  end

  test "cmp_vector_optimized"

  test "splat"

  test "shuffle"

  test "select"

  test "vector_store_elem"
end
