defmodule ClrTest.AirParsers.PointersTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  describe "pointer operations" do
    alias Clr.Air.Instruction.Pointers.Op

    test "ptr_add" do
      assert %Op{
               op: :add,
               type: {:ptr, :many, ~l"usize", []},
               src: {0, :keep},
               val: ~l"@Air.Inst.Ref.zero_usize"
             } =
               Instruction.parse("ptr_add([*]usize, %0, @Air.Inst.Ref.zero_usize)")
    end

    test "ptr_sub" do
      assert %Op{
               op: :sub,
               type: {:ptr, :many, ~l"usize", []},
               src: {0, :keep},
               val: ~l"@Air.Inst.Ref.zero_usize"
             } =
               Instruction.parse("ptr_sub([*]usize, %0, @Air.Inst.Ref.zero_usize)")
    end
  end
end
