defmodule ClrTest.AirParsers.ControlsTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction.Controls.RetPtr

  test "ret_ptr" do
    assert %RetPtr{type: {:ptr, :one, ~l"fs.File", []}} = Instruction.parse("ret_ptr(*fs.File)")
  end
end
