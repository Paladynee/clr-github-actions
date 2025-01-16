defmodule ClrTest.AirParsers.CastsTest do
  use ExUnit.Case, async: true

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction
  alias Clr.Air.Instruction.Casts.Bitcast

  test "bitcast" do
    assert %Bitcast{type: {:ptr, :many, ~l"elf.Elf64_auxv_t", []}, src: {65, :clobber}} =
             Instruction.parse("bitcast([*]elf.Elf64_auxv_t, %65!)")
  end
end
