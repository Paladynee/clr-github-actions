defmodule ClrTest.AirParsers.MathsTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  describe "binary operations" do
    alias Clr.Air.Instruction.Maths.Binary

    # add and friends

    test "add" do
      assert %Binary{op: :add, lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize", mode: nil} =
               Instruction.parse("add(%19, @Air.Inst.Ref.one_usize)")
    end

    test "add_sat" do
      assert %Binary{op: :add, lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize", mode: :sat} =
               Instruction.parse("add_sat(%19, @Air.Inst.Ref.one_usize)")
    end

    test "add_wrap" do
      assert %Binary{op: :add, lhs: {206, :clobber}, rhs: {207, :clobber}, mode: :wrap} =
               Instruction.parse("add_wrap(%206!, %207!)")
    end

    # sub and friends

    test "sub" do
      assert %Binary{op: :sub, lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize", mode: nil} =
               Instruction.parse("sub(%19, @Air.Inst.Ref.one_usize)")
    end

    test "sub_sat" do
      assert %Binary{op: :sub, lhs: {206, :clobber}, rhs: {207, :clobber}, mode: :sat} =
               Instruction.parse("sub_sat(%206!, %207!)")
    end

    test "sub_wrap" do
      assert %Binary{op: :sub, lhs: {206, :clobber}, rhs: {207, :clobber}, mode: :wrap} =
               Instruction.parse("sub_wrap(%206!, %207!)")
    end

    # mul and friends

    test "mul" do
      assert %Binary{op: :mul, lhs: {206, :clobber}, rhs: {207, :clobber}, mode: nil} =
               Instruction.parse("mul(%206!, %207!)")
    end

    test "mul_sat" do
      assert %Binary{op: :mul, lhs: {206, :clobber}, rhs: {207, :clobber}, mode: :sat} =
               Instruction.parse("mul_sat(%206!, %207!)")
    end

    test "mul_wrap" do
      assert %Binary{op: :mul, lhs: {206, :clobber}, rhs: {207, :clobber}, mode: :wrap} =
               Instruction.parse("mul_wrap(%206!, %207!)")
    end

    # division operations

    test "mod" do
      assert %Binary{op: :mod, lhs: {206, :clobber}, rhs: {:literal, ~l"usize", 8}} =
               Instruction.parse("mod(%206!, <usize, 8>)")
    end

    test "rem" do
      assert %Binary{op: :rem, lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("rem(%96, %97)")
    end

    test "div_exact" do
      assert %Binary{op: :div, lhs: {206, :clobber}, rhs: {:literal, ~l"usize", 8}, mode: :exact} =
               Instruction.parse("div_exact(%206!, <usize, 8>)")
    end

    test "div_trunc" do
      assert %Binary{op: :div, lhs: {206, :clobber}, rhs: {:literal, ~l"usize", 8}, mode: :trunc} =
               Instruction.parse("div_trunc(%206!, <usize, 8>)")
    end

    # min/max

    test "min" do
      assert %Binary{op: :min, lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("min(%96, %97)")
    end

    test "max" do
      assert %Binary{op: :max, lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("max(%96, %97)")
    end

    # shift operations

    test "shr" do
      assert %Binary{op: :shr, lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize"} =
               Instruction.parse("shr(%19, @Air.Inst.Ref.one_usize)")
    end

    test "shl" do
      assert %Binary{op: :shl, lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize"} =
               Instruction.parse("shl(%19, @Air.Inst.Ref.one_usize)")
    end

    # bitwise operations

    test "bit_and" do
      assert %Binary{op: :bit_and, lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("bit_and(%96, %97)")
    end

    test "bit_or" do
      assert %Binary{op: :bit_or, lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("bit_or(%96, %97)")
    end

    test "xor" do
      assert %Binary{op: :xor, lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("xor(%96, %97)")
    end

    # boolean binary operations

    test "bool_or" do
      assert %Binary{op: :bool_or, lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("bool_or(%96, %97)")
    end

    test "bool_and" do
      assert %Binary{op: :bool_and, lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("bool_and(%96, %97)")
    end
  end

  describe "unary + type operations" do
    alias Clr.Air.Instruction.Maths.UnaryTyped

    test "not" do
      assert %UnaryTyped{op: :not, operand: {96, :keep}, type: ~l"usize"} =
               Instruction.parse("not(usize, %96)")
    end

    test "abs" do
      assert %UnaryTyped{op: :abs, operand: {96, :keep}, type: ~l"usize"} =
               Instruction.parse("abs(usize, %96)")
    end

    test "clz" do
      assert %UnaryTyped{op: :clz, operand: {96, :keep}, type: ~l"usize"} =
               Instruction.parse("clz(usize, %96)")
    end

    test "byte_swap" do
      assert %UnaryTyped{op: :byte_swap, type: ~l"u64", operand: {0, :keep}} =
               Instruction.parse("byte_swap(u64, %0)")
    end

    test "bit_reverse" do
      assert %UnaryTyped{op: :bit_reverse, type: ~l"u64", operand: {0, :keep}} =
               Instruction.parse("bit_reverse(u64, %0)")
    end
  end

  describe "overflow operations" do
    alias Clr.Air.Instruction.Maths.Overflow

    test "add_with_overflow" do
      assert %Overflow{
               op: :add,
               lhs: {96, :keep},
               rhs: ~l"@Air.Inst.Ref.one_usize",
               type: {:struct, [~l"usize", ~l"u1"]}
             } =
               Instruction.parse(
                 "add_with_overflow(struct { usize, u1 }, %96, @Air.Inst.Ref.one_usize)"
               )
    end

    test "sub_with_overflow" do
      assert %Overflow{
               op: :sub,
               lhs: {96, :keep},
               rhs: ~l"@Air.Inst.Ref.one_usize",
               type: {:struct, [~l"usize", ~l"u1"]}
             } =
               Instruction.parse(
                 "sub_with_overflow(struct { usize, u1 }, %96, @Air.Inst.Ref.one_usize)"
               )
    end

    test "mul_with_overflow" do
      assert %Overflow{
               op: :mul,
               lhs: {96, :keep},
               rhs: ~l"@Air.Inst.Ref.one_usize",
               type: {:struct, [~l"usize", ~l"u1"]}
             } =
               Instruction.parse(
                 "mul_with_overflow(struct { usize, u1 }, %96, @Air.Inst.Ref.one_usize)"
               )
    end

    test "shl_with_overflow" do
      assert %Overflow{
               op: :shl,
               lhs: {96, :keep},
               rhs: ~l"@Air.Inst.Ref.one_usize",
               type: {:struct, [~l"usize", ~l"u1"]}
             } =
               Instruction.parse(
                 "shl_with_overflow(struct { usize, u1 }, %96, @Air.Inst.Ref.one_usize)"
               )
    end
  end
end
