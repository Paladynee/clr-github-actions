defmodule ClrTest.AirParsers.VectorTests do
  use ExUnit.Case, async: true

  import Clr.Air.Lvalue

  alias ClrTest.TestAir

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

  test "cmp_vector_optimized" do
    assert %Cmp{
             op: :neq,
             lhs: {405, :clobber},
             rhs: {:literal, {:lvalue, [{:vector, {:lvalue, ["u8"]}, 16}]}, _},
             optimized: true
           } =
             Instruction.parse(
               "cmp_vector_optimized(neq, %405!, <@Vector(16, u8), .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }>)"
             )
  end

  alias Clr.Air.Instruction.Vector.Splat

  test "splat" do
    assert %Splat{type: {:lvalue, [{:vector, ~l"bool", 8}]}, src: {13, :clobber}} =
             Instruction.parse("splat(@Vector(8, bool), %13!)")
  end

  alias Clr.Air.Instruction.Vector.Shuffle

  test "shuffle" do
    assert %Shuffle{
             len: 8,
             mask: {:lvalue, [{:comptime_call, ~l"InternPool.Index", [3021]}]},
             b: {25, :clobber},
             a: {24, :clobber}
           } = Instruction.parse("shuffle(%24!, %25!, mask InternPool.Index(3021), len 8)")
  end

  alias Clr.Air.Instruction.Vector.Select

  test "select" do
    assert %Select{
             type: {:lvalue, ["bool"]},
             a: {25, :clobber},
             b: {26, :clobber},
             pred: {24, :clobber}
           } = Instruction.parse("select(bool, %24!, %25!, %26!)")
  end

  test "vector_store_elem" do
    TestAir.assert_unimplemented("vector_store_elem")
  end
end
