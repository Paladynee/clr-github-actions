defmodule ClrTest.AirParsers.FunctionTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction.Function.Arg

  describe "arg" do
    test "plain" do
      assert %Arg{type: {:ptr, :many, ~l"usize", []}, name: "argc_argv_ptr"} =
               Instruction.parse(~S/arg([*]usize, "argc_argv_ptr")/)
    end

    test "without value" do
      assert %Arg{type: {:ptr, :many, ~l"usize", []}, name: nil} =
               Instruction.parse(~S/arg([*]usize)/)
    end
  end

  alias Clr.Air.Instruction.Function.RetPtr

  test "ret_ptr" do
    assert %RetPtr{type: {:ptr, :one, ~l"fs.File", []}} = Instruction.parse("ret_ptr(*fs.File)")
  end

  alias Clr.Air.Instruction.Function.FrameAddr

  test "frame_addr" do
    assert %FrameAddr{} = Instruction.parse("frame_addr()")
  end

  alias Clr.Air.Instruction.Function.Call

  describe "call" do
    test "plain" do
      assert %Call{
               fn: {:literal, {:fn, _, _, _}, {:function, "initStatic"}},
               args: [{74, :keep}]
             } =
               Instruction.parse(
                 "call(<fn ([]elf.Elf64_Phdr) void, (function 'initStatic')>, [%74])"
               )

      assert %Call{fn: {10, :keep}, args: []} = Instruction.parse("call(%10, [])")

      assert %Call{
               args: [
                 {:literal, {:lvalue, ["os", "linux", "rlimit_resource__enum_2617"]},
                  {:enum, "STACK"}}
               ],
               opt: nil,
               fn: _
             } =
               Instruction.parse(
                 "call(<fn (os.linux.rlimit_resource__enum_2617) error{Unexpected}!os.linux.rlimit, (function 'getrlimit')>, [<os.linux.rlimit_resource__enum_2617, .STACK>])"
               )
    end

    test "always_tail" do
      assert %Call{opt: :always_tail} =
               Instruction.parse(
                 "call_always_tail(<fn ([]elf.Elf64_Phdr) void, (function 'initStatic')>, [%74])"
               )
    end

    test "never_tail" do
      assert %Call{opt: :never_tail} =
               Instruction.parse(
                 "call_never_tail(<fn ([]elf.Elf64_Phdr) void, (function 'initStatic')>, [%74])"
               )
    end

    test "never inline" do
      assert %Call{opt: :never_inline} =
               Instruction.parse(
                 "call_never_inline(<fn ([]elf.Elf64_Phdr) void, (function 'initStatic')>, [%74])"
               )
    end
  end

  describe "ret functions" do
    alias Clr.Air.Instruction.Function.Ret

    test "ret" do
      assert %Ret{val: ~l"@Air.Inst.Ref.void_value", mode: nil} =
               Instruction.parse("ret(@Air.Inst.Ref.void_value)")
    end

    test "ret_safe" do
      assert %Ret{val: ~l"@Air.Inst.Ref.void_value", mode: :safe} =
               Instruction.parse("ret_safe(@Air.Inst.Ref.void_value)")
    end

    test "ret_load" do
      assert %Ret{val: {19, :keep}, mode: :load} = Instruction.parse("ret_load(%19)")
    end
  end
end
