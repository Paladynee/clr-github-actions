defmodule ClrTest.AirParsers.InstructionTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  setup(do: {:ok, empty_map: %{}})

  describe "control flow instructions" do
    alias Clr.Air.Instruction.ControlFlow.CondBr

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

    alias Clr.Air.Instruction.ControlFlow.Repeat

    test "repeat" do
      assert %Repeat{goto: {23, :keep}} =
               Instruction.parse("repeat(%23)")
    end
  end

  describe "memory operations" do
    alias Clr.Air.Instruction.GetUnionTag

    # do
    test "get_union_tag"
    #  assert %GetUnionTag{loc: {298, :keep}, type: {:lvalue, _}} =
    #           Instruction.parse(
    #             "get_union_tag(@typeInfo(debug.Dwarf.readEhPointer__union_4486).@\"union\".tag_type.?, %298)"
    #           )
    # end
  end

  # other instructions

  alias Clr.Air.Instruction.Assembly

  test "assembly" do
    assert %Assembly{type: ~l"void"} =
             Instruction.parse(
               ~S/assembly(void, volatile, [_start] in X = (<*const fn () callconv(.naked) noreturn, start._start>), [posixCallMainAndExit] in X = (<*const fn ([*]usize) callconv(.c) noreturn, start.posixCallMainAndExit>), " .cfi_undefined %%rip\n xorl %%ebp, %%ebp\n movq %%rsp, %%rdi\n andq $-16, %%rsp\n callq %[posixCallMainAndExit:P]")/
             )
  end

  test "complex assembly" do
    assert %Assembly{type: ~l"usize", code: "syscall"} =
             Instruction.parse(
               ~S/assembly(usize, volatile, [ret] -> ={rax}, [number] in {rax} = (<usize, 9>), [arg1] in {rdi} = (@Air.Inst.Ref.zero_usize), [arg2] in {rsi} = (%59!), [arg3] in {rdx} = (<usize, 3>), [arg4] in {r10} = (<usize, 34>), [arg5] in {r8} = (<usize, 18446744073709551615>), [arg6] in {r9} = (@Air.Inst.Ref.zero_usize), ~{rcx}, ~{r11}, ~{memory}, "syscall")/
             )
  end

  test "assembly, with clobbers and in/outs" do
    assert %Clr.Air.Instruction.Assembly{
             type: {:lvalue, ["usize"]},
             code: " callq %[getContextInternal:P]",
             clobbers: ["r11", "r10", "r8", "rsi", "rdx", "rcx", "memory", "cc"],
             in: [
               {~l"rdi", [~l"_"], {8, :keep}},
               {~l"X", [~l"getContextInternal"],
                {:literal, {:fn, [], ~l"usize", [callconv: :naked]},
                 ~l"os.linux.x86_64.getContextInternal"}}
             ],
             out: [{~l"rdi", [~l"_"], {20, :clobber}}],
             ->: [{~l"_", ~l"rax"}]
           } =
             Instruction.parse(
               ~S/assembly(usize, volatile, [_] -> ={rax}, [_] out ={rdi} = (%20!), [_] in {rdi} = (%8), [getContextInternal] in X = (<*const fn () callconv(.naked) usize, os.linux.x86_64.getContextInternal>), ~{cc}, ~{memory}, ~{rcx}, ~{rdx}, ~{rsi}, ~{r8}, ~{r10}, ~{r11}, " callq %[getContextInternal:P]")/
             )
  end
end
