defmodule ClrTest.AirParsers.ControlFlowTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  describe "block" do
    alias Clr.Air.Instruction.ControlFlow.Block

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

  alias Clr.Air.Instruction.ControlFlow.Loop

  test "loop" do
    assert %Loop{type: ~l"void"} =
             Instruction.parse("""
             loop(void, { 
               %7!= dbg_stmt(2:13) 
             })
             """)
  end

  alias Clr.Air.Instruction.ControlFlow.Br

  test "br" do
    assert %Br{
             value: ~l"@Air.Inst.Ref.void_value",
             goto: {5, :keep}
           } = Instruction.parse("br(%5, @Air.Inst.Ref.void_value)")
  end

  describe "cond_br" do
    alias Clr.Air.Instruction.ControlFlow.CondBr

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
  end

  describe "switch_br" do
    alias Clr.Air.Instruction.ControlFlow.SwitchBr

    test "basic" do
      assert %SwitchBr{test: {104, :clobber}} =
               Instruction.parse("""
               switch_br(%104!, [<u64, 5>] => {
                   %120!= br(%109, @Air.Inst.Ref.void_value)
                 }
               )
               """)
    end

    test "loop_switch_br" do
      assert %SwitchBr{test: {104, :clobber}, loop: true} =
               Instruction.parse("""
               loop_switch_br(%104!, [<u64, 5>] => {
                   %120!= br(%109, @Air.Inst.Ref.void_value)
                 }
               )
               """)
    end

    test "else with .cold" do
      assert %SwitchBr{
               test: {300, :clobber},
               cases: %{:else => %{{333, :clobber} => _}}
             } =
               Instruction.parse("""
               switch_br(%300!, [<@typeInfo(debug.Dwarf.readEhPointer__union_4492).@"union".tag_type.?, .signed>] => {
                   %328!= br(%301, %327!)
                 }, [<@typeInfo(debug.Dwarf.readEhPointer__union_4492).@"union".tag_type.?, .unsigned>] => {
                   %332!= br(%301, %331!)
                 }, else .cold => {
                   %333!= dbg_stmt(35:44)
                   %335!= unreach()
                 }
               )
               """)
    end
  end

  describe "switch_dispatch" do
    alias Clr.Air.Instruction.ControlFlow.SwitchDispatch

    test "switch_dispatch" do
      %SwitchDispatch{fwd: {44, :clobber}, goto: {49, :keep}} =
        Instruction.parse("switch_dispatch(%49, %44!)")
    end
  end

  describe "try" do
    alias Clr.Air.Instruction.ControlFlow.Try

    test "basic" do
      assert %Try{src: {12, :keep}, error_code: %{}, clobbers: [12]} =
               Instruction.parse("""
               try(%12, {
                 %13 = unwrap_errunion_err(error{MissingDebugInfo,UnsupportedOperatingSystem}, %12!)
                 %14!= dbg_stmt(5:27)
                 %15 = bitcast(@typeInfo(@typeInfo(@TypeOf(debug.getSelfDebugInfo)).@"fn".return_type.?).error_union.error_set, %13!)
                 %16 = wrap_errunion_err(@typeInfo(@typeInfo(@TypeOf(debug.getSelfDebugInfo)).@"fn".return_type.?).error_union.error_set!*debug.SelfInfo, %15!)
                 %17!= ret_safe(%16!)
               } %12!)
               """)
    end

    test "try_cold" do
      assert %Try{src: {28, :keep}, error_code: %{}, clobbers: [28], cold: true} =
               Instruction.parse("""
               try_cold(%28, {
                 %24! %4! %1! %0!
                 %29 = unwrap_errunion_err(error{OutOfMemory}, %28!)
                 %30!= dbg_stmt(8:13)
                 %31 = wrap_errunion_err(error{OutOfMemory}!void, %29!)
                 %32!= ret_safe(%31!)
               } %28!)
               """)
    end
  end

  describe "try_ptr" do
    alias Clr.Air.Instruction.ControlFlow.TryPtr

    test "basic" do
      assert %TryPtr{
               src: {259, :keep},
               type:
                 {:ptr, :one, {:ptr, :slice, {:lvalue, ["u8"]}, [const: true]}, [const: true]},
               error_code: %{:clobbers => [5, 247, 248]},
               clobbers: [259]
             } =
               Instruction.parse("""
               try_ptr(%259, *const []const u8, {
                 %247! %5! %248!
                 %261 = unwrap_errunion_err_ptr(error{Overflow,EndOfBuffer,InvalidBuffer}, %259!)
                 %262!= dbg_stmt(35:38)
                 %263 = bitcast(error{MissingDebugInfo,InvalidDebugInfo,OutOfMemory,Overflow,EndOfBuffer,InvalidBuffer}, %261!)
                 %264 = wrap_errunion_err(error{MissingDebugInfo,InvalidDebugInfo,OutOfMemory,Overflow,EndOfBuffer,InvalidBuffer}!debug.Dwarf.FormValue, %263!)
                 %265!= ret_safe(%264!)
               } %259!)
               """)
    end

    test "cold" do
      assert %TryPtr{
               src: {259, :keep},
               cold: true
             } =
               Instruction.parse("""
               try_ptr_cold(%259, *const []const u8, {
                 %247! %5! %248!
                 %261 = unwrap_errunion_err_ptr(error{Overflow,EndOfBuffer,InvalidBuffer}, %259!)
                 %262!= dbg_stmt(35:38)
                 %263 = bitcast(error{MissingDebugInfo,InvalidDebugInfo,OutOfMemory,Overflow,EndOfBuffer,InvalidBuffer}, %261!)
                 %264 = wrap_errunion_err(error{MissingDebugInfo,InvalidDebugInfo,OutOfMemory,Overflow,EndOfBuffer,InvalidBuffer}!debug.Dwarf.FormValue, %263!)
                 %265!= ret_safe(%264!)
               } %259!)
               """)
    end
  end

  test "unreach" do
    alias Clr.Air.Instruction.ControlFlow.Unreach

    assert %Unreach{} = Instruction.parse("unreach()")
  end
end
