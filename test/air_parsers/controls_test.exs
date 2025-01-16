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

  alias Clr.Air.Instruction.Controls.Loop

  test "loop" do
    assert %Loop{type: ~l"void"} =
             Instruction.parse("""
             loop(void, { 
               %7!= dbg_stmt(2:13) 
             })
             """)
  end

  alias Clr.Air.Instruction.Controls.Br

  test "br" do
    assert %Br{
             value: ~l"@Air.Inst.Ref.void_value",
             goto: {5, :keep}
           } = Instruction.parse("br(%5, @Air.Inst.Ref.void_value)")
  end

  alias Clr.Air.Instruction.Controls.FrameAddr

  test "frame_addr" do
    assert %FrameAddr{} = Instruction.parse("frame_addr()")
  end

  alias Clr.Air.Instruction.Controls.Call

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

  describe "cond_br" do
    alias Clr.Air.Instruction.Controls.CondBr

    test "plain" do
      assert %CondBr{} =
               Instruction.parse("""
               cond_br(%146!, poi {
                 %147!= unwrap_errunion_payload(void, %107)
                 %148!= br(%104, @Air.Inst.Ref.void_value)
               }, poi {
                 %2! %1!
                 %149!= unwrap_errunion_err(error{Unexpected,DiskQuota,FileTooBig,InputOutput,NoSpaceLeft,DeviceBusy,InvalidArgument,AccessDenied,BrokenPipe,SystemResources,OperationAborted,NotOpenForWriting,LockViolation,WouldBlock,ConnectionResetByPeer,ProcessNotFound}, %107)
                 %150!= dbg_stmt(88:64)
                 %151!= call(<fn () noreturn, (function 'abort')>, [])
                 %152!= unreach()
               })
               """)
    end

    test "other cond_br features"
  end

  describe "switch_br" do
    alias Clr.Air.Instruction.Controls.SwitchBr
    test "switch_br" do
      assert %SwitchBr{test: {104, :clobber}} =
               Instruction.parse("""
               switch_br(%104!, [<u64, 5>] => {
                   %120!= br(%109, @Air.Inst.Ref.void_value)
                 }
               )
               """)
    end

    test "other switch_br features"
  end
end
