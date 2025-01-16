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
end
