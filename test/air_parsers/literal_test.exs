defmodule ClrTest.Air.LiteralTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Type

  test "generic literal"

  test "integer literal"

  test "const * function literal" do
    assert {:literal, {:fn, [], "noreturn", [callconv: :naked]}, "start._start"} =
             Type.parse_literal("<*const fn () callconv(.naked) noreturn, start._start>")
  end
end
