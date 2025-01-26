defmodule ClrTest.AirParsers.TestsTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  describe "compare operations" do
    alias Clr.Air.Instruction.Tests.Compare

    test "cmp_lt" do
      assert %Compare{op: :lt, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_lt(%95!, %96!)")
    end

    test "cmp_lt_optimized" do
      assert %Compare{op: :lt, lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}, optimized: true} =
               Instruction.parse("cmp_lt_optimized(%95!, <u64, 0>)")
    end

    test "cmp_lte" do
      assert %Compare{op: :lte, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_lte(%95!, %96!)")
    end

    test "cmp_lte_optimized" do
      assert %Compare{op: :lte, lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}, optimized: true} =
               Instruction.parse("cmp_lte_optimized(%95!, <u64, 0>)")
    end

    test "cmp_eq" do
      assert %Compare{op: :eq, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_eq(%95!, %96!)")
    end

    test "cmp_eq_optimized" do
      assert %Compare{op: :eq, lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}, optimized: true} =
               Instruction.parse("cmp_eq_optimized(%95!, <u64, 0>)")
    end

    test "cmp_gte" do
      assert %Compare{op: :gte, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_gte(%95!, %96!)")
    end

    test "cmp_gte_optimized" do
      assert %Compare{op: :gte, lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}, optimized: true} =
               Instruction.parse("cmp_gte_optimized(%95!, <u64, 0>)")
    end

    test "cmp_gt" do
      assert %Compare{op: :gt, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_gt(%95!, %96!)")
    end

    test "cmp_gt_optimized" do
      assert %Compare{op: :gt, lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}, optimized: true} =
               Instruction.parse("cmp_gt_optimized(%95!, <u64, 0>)")
    end

    test "cmp_neq" do
      assert %Compare{op: :neq, lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}} =
               Instruction.parse("cmp_neq(%95!, <u64, 0>)")
    end

    test "cmp_neq_optimized" do
      assert %Compare{op: :neq, lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}, optimized: true} =
               Instruction.parse("cmp_neq_optimized(%95!, <u64, 0>)")
    end
  end

  describe "is operations" do
    alias Clr.Air.Instruction.Tests.Is

    test "is_null" do
      assert %Is{op: :null, operand: {95, :clobber}} =
               Instruction.parse("is_null(%95!)")
    end

    test "is_non_null" do
      assert %Is{op: :non_null, operand: {95, :clobber}} =
               Instruction.parse("is_non_null(%95!)")
    end

    test "is_null_ptr" do
      assert %Is{op: :null_ptr, operand: {95, :clobber}} =
               Instruction.parse("is_null_ptr(%95!)")
    end

    test "is_non_null_ptr" do
      assert %Is{op: :non_null_ptr, operand: {95, :clobber}} =
               Instruction.parse("is_non_null_ptr(%95!)")
    end

    test "is_err" do
      assert %Is{op: :err, operand: {95, :clobber}} =
               Instruction.parse("is_err(%95!)")
    end

    test "is_non_err" do
      assert %Is{op: :non_err, operand: {95, :clobber}} =
               Instruction.parse("is_non_err(%95!)")
    end

    test "is_err_ptr" do
      assert %Is{op: :err_ptr, operand: {95, :clobber}} =
               Instruction.parse("is_err_ptr(%95!)")
    end

    test "is_non_err_ptr" do
      assert %Is{op: :non_err_ptr, operand: {95, :clobber}} =
               Instruction.parse("is_non_err_ptr(%95!)")
    end

    test "is_named_enum_value" do
      assert %Is{op: :named_enum_value, operand: {95, :clobber}} =
               Instruction.parse("is_named_enum_value(%95!)")
    end
  end

  alias Clr.Air.Instruction.Tests.CmpLtErrorsLen

  test "cmp_lt_errors_len" do
    assert %CmpLtErrorsLen{src: {96, :clobber}} =
             Instruction.parse("cmp_lt_errors_len(%96!)")
  end

  alias Clr.Air.Instruction.Tests.ErrorSetHasValue

  test "error_set_has_value" do
    assert %ErrorSetHasValue{type: ~l"u8", src: {96, :clobber}} =
             Instruction.parse("error_set_has_value(u8, %96!)")
  end
end
