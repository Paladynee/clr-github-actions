defmodule ClrTest.AirParsers.MemTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction.Mem.Load

  test "load" do
    assert %Load{type: {:ptr, :many, ~l"usize", []}, src: {19, :keep}} =
             Instruction.parse("load([*]usize, %19)")
  end
end
