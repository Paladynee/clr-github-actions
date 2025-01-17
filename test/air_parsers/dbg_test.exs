defmodule ClrTest.AirParsers.DbgTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  alias Clr.Air.Instruction.Dbg
  alias Clr.Air.Instruction.Dbg.Trap

  import Clr.Air.Lvalue

  test "trap" do
    assert %Trap{} = Instruction.parse("trap()")
  end

  test "breakpoint"

  test "dbg_stmt" do
    assert %Dbg.Stmt{loc: {9, 10}} = Instruction.parse("dbg_stmt(9:10)")
  end

  describe "dbg_inline_block" do
    test "plain" do
      assert %Dbg.InlineBlock{
               type: ~l"void",
               what: {:literal, {:fn, _, _, _}, {:function, "isRISCV"}},
               code: %{}
             } =
               Instruction.parse("""
               dbg_inline_block(void, <fn (Target.Cpu.Arch) callconv(.@"inline") bool, (function 'isRISCV')>, {
                 %7!= dbg_stmt(2:13)
               })
               """)
    end

    test "with clobbers" do
      assert %Dbg.InlineBlock{} =
               Instruction.parse("""
               dbg_inline_block(void, <fn (usize, [*][*:0]u8, [][*:0]u8) callconv(.@"inline") u8, (function 'callMainWithArgs')>, {
                 %240!= dbg_arg_inline(%2, "argc")
               } %8! %2! %54!)
               """)
    end
  end

  test "dbg_var_ptr" do
    assert %Dbg.VarPtr{src: {0, :keep}, val: "envp_count"} =
             Instruction.parse(~S/dbg_var_ptr(%0, "envp_count")/)
  end

  test "dbg_var_val" do
    assert %Dbg.VarVal{src: {0, :keep}, val: "argc"} =
             Instruction.parse(~S/dbg_var_val(%0, "argc")/)

    # more complex case

    assert %Dbg.VarVal{} =
             Instruction.parse(
               ~S/dbg_var_val(<?[*]*const fn () callconv(.c) void, @as([*]*const fn () callconv(.c) void, @ptrCast(__init_array_start))>, "opt_init_array_start")/
             )
  end

  test "dbg_arg_inline" do
    assert %Dbg.ArgInline{val: {:literal, ~l"Target.Cpu.Arch", {:enum, "x86_64"}}, key: "arch"} =
             Instruction.parse("dbg_arg_inline(<Target.Cpu.Arch, .x86_64>, \"arch\")")
  end
end
