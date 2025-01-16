defmodule ClrTest.AirParsers.DebugsTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  alias Clr.Air.Instruction.Debugs.Trap

  test "trap" do
    assert %Trap{} = Instruction.parse("trap()")
  end
end
