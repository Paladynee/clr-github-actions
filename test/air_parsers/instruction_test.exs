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
    alias Clr.Air.Instruction.Alloc

    test "alloc" do
      assert %Alloc{type: {:ptr, :one, ~l"usize", []}} = Instruction.parse("alloc(*usize)")
    end

    alias Clr.Air.Instruction.AggregateInit

    test "aggregate_init" do
      assert %AggregateInit{} =
               Instruction.parse(
                 "aggregate_init(struct { comptime @Type(.enum_literal) = .mmap, comptime usize = 0, usize, comptime usize = 3, comptime u32 = 34, comptime usize = 18446744073709551615, comptime u64 = 0 }, [<@Type(.enum_literal), .mmap>, @Air.Inst.Ref.zero_usize, %44!, <usize, 3>, <u32, 34>, <usize, 18446744073709551615>, <u64, 0>])"
               )
    end

    alias Clr.Air.Instruction.UnionInit

    test "union_init" do
      assert %UnionInit{src: {18, :clobber}, val: 0} = Instruction.parse("union_init(0, %18!)")
    end

    alias Clr.Air.Instruction.Memcpy

    test "memcpy" do
      assert %Memcpy{loc: {104, :clobber}, val: {112, :clobber}} =
               Instruction.parse("memcpy(%104!, %112!)")
    end

    alias Clr.Air.Instruction.GetUnionTag

    test "get_union_tag" # do
    #  assert %GetUnionTag{loc: {298, :keep}, type: {:lvalue, _}} =
    #           Instruction.parse(
    #             "get_union_tag(@typeInfo(debug.Dwarf.readEhPointer__union_4486).@\"union\".tag_type.?, %298)"
    #           )
    #end

  end

  describe "test operations" do
    # TODO: set off into "vector" domain
    alias Clr.Air.Instruction.CmpVector

    test "cmp_vector" do
      assert %CmpVector{
               op: :neq,
               lhs: {405, :clobber},
               rhs: {:literal, {:lvalue, [{:vector, {:lvalue, ["u8"]}, 16}]}, _}
             } =
               Instruction.parse(
                 "cmp_vector(neq, %405!, <@Vector(16, u8), .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }>)"
               )
    end
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

  alias Clr.Air.Instruction.Arg

  test "arg" do
    assert %Arg{type: {:ptr, :many, ~l"usize", []}, name: "argc_argv_ptr"} =
             Instruction.parse(~S/arg([*]usize, "argc_argv_ptr")/)
  end

  test "arg without value" do
    assert %Arg{type: {:ptr, :many, ~l"usize", []}, name: nil} =
             Instruction.parse(~S/arg([*]usize)/)
  end
end
