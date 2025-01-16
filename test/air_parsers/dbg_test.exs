defmodule ClrTest.AirParsers.DbgTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  alias Clr.Air.Instruction.Dbg
  alias Clr.Air.Instruction.Dbg.Trap

  test "trap" do
    assert %Trap{} = Instruction.parse("trap()")
  end

  test "breakpoint"

  test "dbg_stmt" do
    assert %Dbg.Stmt{loc: {9, 10}} = Instruction.parse("dbg_stmt(9:10)")
  end
end
