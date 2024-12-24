defmodule ClrTest.AirParsers.TestsTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  describe "compare operations" do
    alias Clr.Air.Instruction.Tests.Compare

    # add and friends

    test "cmp_neq" do
      assert %Compare{op: :neq, lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}} =
               Instruction.parse("cmp_neq(%95!, <u64, 0>)")
    end

    test "cmp_lt" do
      assert %Compare{op: :lt, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_lt(%95!, %96!)")
    end

    test "cmp_lte" do
      assert %Compare{op: :lte, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_lte(%95!, %96!)")
    end

    test "cmp_gt" do
      assert %Compare{op: :gt, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_gt(%95!, %96!)")
    end

    test "cmp_gte" do
      assert %Compare{op: :gte, lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_gte(%95!, %96!)")
    end
  end
end
