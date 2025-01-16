defmodule ClrTest.AirParsers.ControlsTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction.Controls.RetPtr

  test "ret_ptr" do
    assert %RetPtr{type: {:ptr, :one, ~l"fs.File", []}} = Instruction.parse("ret_ptr(*fs.File)")
  end

  describe "block" do
    alias Clr.Air.Instruction.Controls.Block

    test "generic" do
      assert %Block{} =
               Instruction.parse("""
               block(void, {
                 %7!= dbg_stmt(2:13)
               })
               """)
    end

    test "with clobbers" do
      assert %Block{clobbers: [8, 9]} =
               Instruction.parse("""
               block(void, {
                 %7!= dbg_stmt(2:13)
               } %8! %9!)
               """)
    end
  end

  alias Clr.Air.Instruction.Controls.Loop

  test "loop" do
    assert %Loop{type: ~l"void"} =
             Instruction.parse("""
             loop(void, { 
               %7!= dbg_stmt(2:13) 
             })
             """)
  end

  alias Clr.Air.Instruction.Controls.Br

  test "br" do
    assert %Br{
             value: ~l"@Air.Inst.Ref.void_value",
             goto: {5, :keep}
           } = Instruction.parse("br(%5, @Air.Inst.Ref.void_value)")
  end
end
