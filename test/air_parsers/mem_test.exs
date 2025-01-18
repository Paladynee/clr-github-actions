defmodule ClrTest.AirParsers.MemTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction.Mem.Load

  test "load" do
    assert %Load{type: {:ptr, :many, ~l"usize", []}, src: {19, :keep}} =
             Instruction.parse("load([*]usize, %19)")
  end

  alias Clr.Air.Instruction.Mem.Store

  describe "store" do
    test "basic" do
      assert %Store{src: ~l"@Air.Inst.Ref.zero_usize", loc: {19, :keep}} =
               Instruction.parse("store(%19, @Air.Inst.Ref.zero_usize)")
    end

    # note that the "safe" extension changes nothing for "Store".
    test "safe" do
      assert %Store{src: ~l"@Air.Inst.Ref.zero_usize", loc: {19, :keep}} =
               Instruction.parse("store_safe(%19, @Air.Inst.Ref.zero_usize)")
    end
  end
end
