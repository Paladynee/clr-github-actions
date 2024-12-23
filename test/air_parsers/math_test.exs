defmodule ClrTest.AirParsers.MathTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  describe "binary operations" do
    alias Clr.Air.Instruction.Math.Binary

    test "add" do
      assert %Binary{op: :add, lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize"} =
               Instruction.parse("add(%19, @Air.Inst.Ref.one_usize)")
    end

    test "add_sat" do
      assert %Binary{op: :add_sat, lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize"} =
               Instruction.parse("add_sat(%19, @Air.Inst.Ref.one_usize)")
    end

    test "add_wrap" do
      assert %Binary{op: :add_wrap, lhs: {206, :clobber}, rhs: {207, :clobber}} =
               Instruction.parse("add_wrap(%206!, %207!)")
    end

    test "sub" do
      assert %Binary{op: :sub, lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize"} =
               Instruction.parse("sub(%19, @Air.Inst.Ref.one_usize)")
    end

    test "sub_sat" do
      assert %Binary{op: :sub_sat, lhs: {206, :clobber}, rhs: {207, :clobber}} =
               Instruction.parse("sub_sat(%206!, %207!)")
    end

    test "sub_wrap" do
      assert %Binary{op: :sub_wrap, lhs: {206, :clobber}, rhs: {207, :clobber}} =
               Instruction.parse("sub_wrap(%206!, %207!)")
    end
  end
end
