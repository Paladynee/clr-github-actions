defmodule ClrTest.AirParsers.InstructionTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  describe "debug instructions" do
    alias Clr.Air.Instruction.DbgStmt

    test "dbg_stmt" do
      assert %DbgStmt{range: 9..10} = Instruction.parse("dbg_stmt(9:10)")
    end

    alias Clr.Air.Instruction.DbgInlineBlock

    test "dbg_inline_block" do
      assert %DbgInlineBlock{
               type: "void",
               what: {:literal, {:fn, _, _, _}, {:function, "isRISCV"}},
               code: %{}
             } =
               Instruction.parse("""
               dbg_inline_block(void, <fn (Target.Cpu.Arch) callconv(.@"inline") bool, (function 'isRISCV')>, {
                 %7!= dbg_stmt(2:13)
               })
               """)
    end

    alias Clr.Air.Instruction.DbgArgInline

    test "dbg_arg_inline" do
      assert %DbgArgInline{val: {:literal, "Target.Cpu.Arch", ".x86_64"}, key: "arch"} =
               Instruction.parse("dbg_arg_inline(<Target.Cpu.Arch, .x86_64>, \"arch\")")
    end

    alias Clr.Air.Instruction.DbgVarVal

    test "dbg_var_val" do
      assert %DbgVarVal{line: {0, :keep}, val: "argc"} =
               Instruction.parse(~S/dbg_var_val(%0, "argc")/)
    end

    alias Clr.Air.Instruction.DbgVarPtr

    test "dbg_var_ptr" do
      assert %DbgVarPtr{line: {0, :keep}, val: "envp_count"} =
               Instruction.parse(~S/dbg_var_ptr(%0, "envp_count")/)
    end
  end

  describe "control flow instructions" do
    alias Clr.Air.Instruction.Br

    test "br" do
      assert %Br{
               value: "@Air.Inst.Ref.void_value",
               goto: {5, :keep}
             } = Instruction.parse("br(%5, @Air.Inst.Ref.void_value)")
    end

    alias Clr.Air.Instruction.Trap

    test "trap" do
      assert %Trap{} = Instruction.parse("trap()")
    end

    alias Clr.Air.Instruction.Loop

    test "loop" do
      assert %Loop{type: "void"} =
               Instruction.parse("""
               loop(void, { 
                 %7!= dbg_stmt(2:13) 
               })
               """)
    end

    alias Clr.Air.Instruction.CondBr

    test "cond_br without clobbers" do
      assert %CondBr{cond: {104, :clobber}} =
               Instruction.parse("""
               cond_br(%104!, poi {
                 %144!= br(%109, @Air.Inst.Ref.void_value)
               }, poi {
                 %144!= br(%109, @Air.Inst.Ref.void_value)
               })
               """)
    end

    test "cond_br with clobbers" do
      assert %CondBr{true_branch: %{clobbers: [122, 123]}} =
               Instruction.parse("""
               cond_br(%104!, poi {
                 %122! %123!
                 %144!= br(%109, @Air.Inst.Ref.void_value)
               }, poi {
                 %144!= br(%109, @Air.Inst.Ref.void_value)
               })
               """)
    end
  end

  test "basic switch" do
    Instruction.parse("""
    switch_br(%104!, [<u64, 5>] => {
        %120!= br(%109, @Air.Inst.Ref.void_value)
      }
    )
    """)
    |> dbg(limit: 25)
  end

  describe "pointer operations" do
    alias Clr.Air.Instruction.PtrElemVal

    test "ptr_elem_val" do
      assert %PtrElemVal{line: {0, :keep}, val: "@Air.Inst.Ref.zero_usize"} =
               Instruction.parse("ptr_elem_val(%0, @Air.Inst.Ref.zero_usize)")
    end

    alias Clr.Air.Instruction.PtrAdd

    test "ptr_add" do
      assert %PtrAdd{
               type: {:ptr, :many, "usize"},
               line: {0, :keep},
               val: "@Air.Inst.Ref.zero_usize"
             } =
               Instruction.parse("ptr_add([*]usize, %0, @Air.Inst.Ref.zero_usize)")
    end
  end

  describe "memory operations" do
    alias Clr.Air.Instruction.Bitcast

    test "bitcast" do
      assert %Bitcast{type: {:ptr, :many, "u8"}, line: {0, :keep}} =
               Instruction.parse("bitcast([*]u8, %0)")
    end

    alias Clr.Air.Instruction.Alloc

    test "alloc" do
      assert %Alloc{type: {:ptr, :one, "usize"}} = Instruction.parse("alloc(*usize)")
    end

    alias Clr.Air.Instruction.Store

    test "store" do
      assert %Store{val: "@Air.Inst.Ref.zero_usize", loc: {19, :keep}} =
               Instruction.parse("store(%19, @Air.Inst.Ref.zero_usize)")
    end

    alias Clr.Air.Instruction.Load

    test "load" do
      assert %Load{type: {:ptr, :many, "usize"}, loc: {19, :keep}} =
               Instruction.parse("load([*]usize, %19)")
    end

    alias Clr.Air.Instruction.OptionalPayload

    test "optional_payload" do
      assert %OptionalPayload{type: "void", loc: {19, :keep}} =
               Instruction.parse("optional_payload(void, %19)")
    end
  end

  describe "block" do
    alias Clr.Air.Instruction.Block

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

  describe "test operations" do
    alias Clr.Air.Instruction.IsNonNull

    test "is_non_null" do
      assert %IsNonNull{line: {19, :keep}} =
               Instruction.parse("is_non_null(%19)")
    end
  end

  # other instructions

  alias Clr.Air.Instruction.Assembly

  test "assembly" do
    assert %Assembly{type: "void"} =
             Instruction.parse(
               ~S/assembly(void, volatile, [_start] in X = (<*const fn () callconv(.naked) noreturn, start._start>), [posixCallMainAndExit] in X = (<*const fn ([*]usize) callconv(.c) noreturn, start.posixCallMainAndExit>), " .cfi_undefined %%rip\n xorl %%ebp, %%ebp\n movq %%rsp, %%rdi\n andq $-16, %%rsp\n callq %[posixCallMainAndExit:P]")/
             )
  end

  alias Clr.Air.Instruction.Arg

  test "arg" do
    assert %Arg{type: {:ptr, :many, "usize"}, name: "argc_argv_ptr"} =
             Instruction.parse(~S/arg([*]usize, "argc_argv_ptr")/)
  end
end
