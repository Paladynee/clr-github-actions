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

  test "splat"

  test "shuffle"

  test "select"

  test "vector_store_elem"
end
