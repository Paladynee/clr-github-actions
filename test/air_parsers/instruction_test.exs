defmodule ClrTest.AirParsers.InstructionTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  describe "debug instructions" do
    alias Clr.Air.Instruction.DbgStmt

    test "dbg_stmt" do
      assert %DbgStmt{range: 9..10} = Instruction.parse("dbg_stmt(9:10)")
    end

    alias Clr.Air.Instruction.DbgInlineBlock

    test "dbg_inline_block" do
      assert %DbgInlineBlock{
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

    test "dbg_inline_block with clobbers" do
      assert %DbgInlineBlock{} =
               Instruction.parse("""
               dbg_inline_block(void, <fn (usize, [*][*:0]u8, [][*:0]u8) callconv(.@"inline") u8, (function 'callMainWithArgs')>, {
                 %240!= dbg_arg_inline(%2, "argc")
               } %8! %2! %54!)
               """)
    end

    alias Clr.Air.Instruction.DbgArgInline

    test "dbg_arg_inline" do
      assert %DbgArgInline{val: {:literal, ~l"Target.Cpu.Arch", {:enum, ~l"x86_64"}}, key: "arch"} =
               Instruction.parse("dbg_arg_inline(<Target.Cpu.Arch, .x86_64>, \"arch\")")
    end

    alias Clr.Air.Instruction.DbgVarVal

    test "dbg_var_val" do
      assert %DbgVarVal{line: {0, :keep}, val: "argc"} =
               Instruction.parse(~S/dbg_var_val(%0, "argc")/)

      # more complex case

      assert %DbgVarVal{} =
               Instruction.parse(
                 ~S/dbg_var_val(<?[*]*const fn () callconv(.c) void, @as([*]*const fn () callconv(.c) void, @ptrCast(__init_array_start))>, "opt_init_array_start")/
               )
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
               value: ~l"@Air.Inst.Ref.void_value",
               goto: {5, :keep}
             } = Instruction.parse("br(%5, @Air.Inst.Ref.void_value)")
    end

    alias Clr.Air.Instruction.Trap

    test "trap" do
      assert %Trap{} = Instruction.parse("trap()")
    end

    alias Clr.Air.Instruction.Loop

    test "loop" do
      assert %Loop{type: ~l"void"} =
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

    alias Clr.Air.Instruction.Repeat

    test "repeat" do
      assert %Repeat{goto: {23, :keep}} =
               Instruction.parse("repeat(%23)")
    end

    alias Clr.Air.Instruction.SwitchBr

    test "basic switch" do
      assert %SwitchBr{test: {104, :clobber}} =
               Instruction.parse("""
               switch_br(%104!, [<u64, 5>] => {
                   %120!= br(%109, @Air.Inst.Ref.void_value)
                 }
               )
               """)
    end

    alias Clr.Air.Instruction.Call

    test "call" do
      assert %Call{
               fn: {:literal, {:fn, _, _, _}, {:function, "initStatic"}},
               args: [{74, :keep}]
             } =
               Instruction.parse(
                 "call(<fn ([]elf.Elf64_Phdr) void, (function 'initStatic')>, [%74])"
               )

      assert %Call{fn: {10, :keep}, args: []} = Instruction.parse("call(%10, [])")

      assert Instruction.parse(
               "call(<fn (os.linux.rlimit_resource__enum_2617) error{Unexpected}!os.linux.rlimit, (function 'getrlimit')>, [<os.linux.rlimit_resource__enum_2617, .STACK>])"
             )
    end

    alias Clr.Air.Instruction.Unreach

    test "unreach" do
      assert %Unreach{} = Instruction.parse("unreach()")
    end

    alias Clr.Air.Instruction.Ret

    test "ret" do
      assert %Ret{val: ~l"@Air.Inst.Ref.void_value"} =
               Instruction.parse("ret(@Air.Inst.Ref.void_value)")
    end

    alias Clr.Air.Instruction.RetSafe

    test "ret_safe" do
      assert %RetSafe{val: ~l"@Air.Inst.Ref.void_value"} =
               Instruction.parse("ret_safe(@Air.Inst.Ref.void_value)")
    end

    alias Clr.Air.Instruction.RetPtr

    test "ret_ptr" do
      assert %RetPtr{type: {:ptr, :one, ~l"fs.File"}} = Instruction.parse("ret_ptr(*fs.File)")
    end

    alias Clr.Air.Instruction.RetLoad

    test "ret_load" do
      assert %RetLoad{val: {19, :keep}} = Instruction.parse("ret_load(%19)")
    end
  end

  describe "pointer operations" do
    alias Clr.Air.Instruction.PtrElemVal

    test "ptr_elem_val" do
      assert %PtrElemVal{line: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_usize"} =
               Instruction.parse("ptr_elem_val(%0, @Air.Inst.Ref.zero_usize)")
    end

    alias Clr.Air.Instruction.PtrAdd

    test "ptr_add" do
      assert %PtrAdd{
               type: {:ptr, :many, ~l"usize"},
               line: {0, :keep},
               val: ~l"@Air.Inst.Ref.zero_usize"
             } =
               Instruction.parse("ptr_add([*]usize, %0, @Air.Inst.Ref.zero_usize)")
    end

    alias Clr.Air.Instruction.Slice

    test "slice" do
      assert %Slice{type: ~l"usize", src: {0, :keep}, len: {2, :clobber}} =
               Instruction.parse("slice(usize, %0, %2!)")
    end

    alias Clr.Air.Instruction.SlicePtr

    test "slice_ptr" do
      assert %SlicePtr{type: ~l"usize", src: {0, :keep}} =
               Instruction.parse("slice_ptr(usize, %0)")
    end

    alias Clr.Air.Instruction.IntFromPtr

    test "int_from_ptr" do
      assert %IntFromPtr{val: {:literal, ptrtyp, {:as, ptrtyp, {:ptrcast, ~l"__init_array_end"}}}} =
               Instruction.parse(
                 "int_from_ptr(<[*]*const fn () callconv(.c) void, @as([*]*const fn () callconv(.c) void, @ptrCast(__init_array_end))>)"
               )
    end

    alias Clr.Air.Instruction.SliceLen

    test "slice_len" do
      assert %SliceLen{type: ~l"usize", src: {0, :keep}} =
               Instruction.parse("slice_len(usize, %0)")
    end

    alias Clr.Air.Instruction.SliceElemVal

    test "slice_elem_val" do
      assert %SliceElemVal{src: {0, :keep}, index: {2, :clobber}} =
               Instruction.parse("slice_elem_val(%0, %2!)")
    end

    alias Clr.Air.Instruction.StructFieldPtrIndex0

    test "struct_field_ptr_index_0" do
      assert %StructFieldPtrIndex0{type: {:ptr, :one, ~l"u32"}, src: {0, :keep}} =
               Instruction.parse("struct_field_ptr_index_0(*u32, %0)")
    end

    alias Clr.Air.Instruction.WrapOptional

    test "wrap_optional" do
      assert %WrapOptional{type: {:optional, ~l"usize"}, src: {0, :keep}} =
               Instruction.parse("wrap_optional(?usize, %0)")
    end
  end

  describe "memory operations" do
    alias Clr.Air.Instruction.Bitcast

    test "bitcast" do
      assert %Bitcast{type: {:ptr, :many, ~l"u8"}, line: {0, :keep}} =
               Instruction.parse("bitcast([*]u8, %0)")
    end

    alias Clr.Air.Instruction.Alloc

    test "alloc" do
      assert %Alloc{type: {:ptr, :one, ~l"usize"}} = Instruction.parse("alloc(*usize)")
    end

    alias Clr.Air.Instruction.Store

    test "store" do
      assert %Store{val: ~l"@Air.Inst.Ref.zero_usize", loc: {19, :keep}} =
               Instruction.parse("store(%19, @Air.Inst.Ref.zero_usize)")
    end

    alias Clr.Air.Instruction.Load

    test "load" do
      assert %Load{type: {:ptr, :many, ~l"usize"}, loc: {19, :keep}} =
               Instruction.parse("load([*]usize, %19)")
    end

    alias Clr.Air.Instruction.OptionalPayload

    test "optional_payload" do
      assert %OptionalPayload{type: ~l"void", loc: {19, :keep}} =
               Instruction.parse("optional_payload(void, %19)")
    end

    alias Clr.Air.Instruction.StructFieldVal

    test "struct_field_val" do
      assert %StructFieldVal{src: {93, :clobber}, index: 0} =
               Instruction.parse("struct_field_val(%93!, 0)")
    end

    alias Clr.Air.Instruction.StoreSafe

    test "store_safe" do
      assert %StoreSafe{val: ~l"@Air.Inst.Ref.zero_usize", loc: {19, :keep}} =
               Instruction.parse("store_safe(%19, @Air.Inst.Ref.zero_usize)")
    end

    alias Clr.Air.Instruction.AggregateInit

    test "aggregate_init" do
      assert %AggregateInit{} =
               Instruction.parse(
                 "aggregate_init(struct { comptime @Type(.enum_literal) = .mmap, comptime usize = 0, usize, comptime usize = 3, comptime u32 = 34, comptime usize = 18446744073709551615, comptime u64 = 0 }, [<@Type(.enum_literal), .mmap>, @Air.Inst.Ref.zero_usize, %44!, <usize, 3>, <u32, 34>, <usize, 18446744073709551615>, <u64, 0>])"
               )
    end

    alias Clr.Air.Instruction.UnwrapErrunionPayload

    test "unwrap_errunion_payload" do
      assert %UnwrapErrunionPayload{type: ~l"usize", src: {0, :keep}} =
               Instruction.parse("unwrap_errunion_payload(usize, %0)")
    end

    alias Clr.Air.Instruction.UnwrapErrunionErr

    test "unwrap_errunion_err" do
      assert %UnwrapErrunionErr{type: {:errorunion, ["Unexpected"]}, src: {0, :keep}} =
               Instruction.parse("unwrap_errunion_err(error{Unexpected}, %0)")
    end

    alias Clr.Air.Instruction.Intcast

    test "intcast" do
      assert %Intcast{type: ~l"usize", line: {0, :keep}} =
               Instruction.parse("intcast(usize, %0)")
    end

    alias Clr.Air.Instruction.Memset

    test "memset" do
      assert %Memset{loc: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_u8"} =
               Instruction.parse("memset(%0, @Air.Inst.Ref.zero_u8)")
    end

    alias Clr.Air.Instruction.Memcpy

    test "memcpy" do
      assert %Memcpy{loc: {104, :clobber}, val: {112, :clobber}} =
               Instruction.parse("memcpy(%104!, %112!)")
    end

    alias Clr.Air.Instruction.WrapErrunionPayload

    test "wrap_errunion_payload" do
      assert %WrapErrunionPayload{
               type: {:errorable, ["Unexpected"], ~l"os.linux.rlimit"},
               src: {16, :clobber}
             } =
               Instruction.parse("wrap_errunion_payload(error{Unexpected}!os.linux.rlimit, %16!)")
    end

    alias Clr.Air.Instruction.WrapErrunionErr

    test "wrap_errunion_err" do
      assert %WrapErrunionErr{
               type: {:errorable, ["Unexpected"], ~l"os.linux.rlimit"},
               src: {16, :clobber}
             } =
               Instruction.parse("wrap_errunion_err(error{Unexpected}!os.linux.rlimit, %16!)")
    end

    alias Clr.Air.Instruction.ArrayToSlice

    test "array_to_slice" do
      assert %ArrayToSlice{type: {:ptr, :slice, ~l"u8"}, src: {13, :clobber}} =
               Instruction.parse("array_to_slice([]u8, %13!)")
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

    alias Clr.Air.Instruction.CmpNeq

    test "cmp_neq" do
      assert %CmpNeq{lhs: {95, :clobber}, rhs: {:literal, ~l"u64", 0}} =
               Instruction.parse("cmp_neq(%95!, <u64, 0>)")
    end

    alias Clr.Air.Instruction.CmpLt

    test "cmp_lt" do
      assert %CmpLt{lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_lt(%95!, %96!)")
    end

    alias Clr.Air.Instruction.CmpLte

    test "cmp_lte" do
      assert %CmpLte{lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_lte(%95!, %96!)")
    end

    alias Clr.Air.Instruction.IsNonErr

    test "is_non_err" do
      assert %IsNonErr{line: {19, :keep}} =
               Instruction.parse("is_non_err(%19)")
    end

    alias Clr.Air.Instruction.CmpGt

    test "cmp_gt" do
      assert %CmpGt{lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_gt(%95!, %96!)")
    end

    alias Clr.Air.Instruction.CmpGte

    test "cmp_gte" do
      assert %CmpGte{lhs: {95, :clobber}, rhs: {96, :clobber}} =
               Instruction.parse("cmp_gte(%95!, %96!)")
    end
  end

  describe "math operations" do
    alias Clr.Air.Instruction.Add

    test "add" do
      assert %Add{lhs: {19, :keep}, rhs: ~l"@Air.Inst.Ref.one_usize"} =
               Instruction.parse("add(%19, @Air.Inst.Ref.one_usize)")
    end

    alias Clr.Air.Instruction.SubWrap

    test "sub_wrap" do
      assert %SubWrap{lhs: {206, :clobber}, rhs: {207, :clobber}} =
               Instruction.parse("sub_wrap(%206!, %207!)")
    end

    alias Clr.Air.Instruction.DivExact

    test "div_exact" do
      assert %DivExact{lhs: {206, :clobber}, rhs: {:literal, ~l"usize", 8}} =
               Instruction.parse("div_exact(%206!, <usize, 8>)")
    end

    alias Clr.Air.Instruction.SubWithOverflow

    test "sub_with_overflow" do
      assert %SubWithOverflow{
               lhs: {96, :keep},
               rhs: ~l"@Air.Inst.Ref.one_usize",
               type: {:struct, [~l"usize", ~l"u1"]}
             } =
               Instruction.parse(
                 "sub_with_overflow(struct { usize, u1 }, %96, @Air.Inst.Ref.one_usize)"
               )
    end

    alias Clr.Air.Instruction.AddWithOverflow

    test "add_with_overflow" do
      assert %AddWithOverflow{
               lhs: {96, :keep},
               rhs: ~l"@Air.Inst.Ref.one_usize",
               type: {:struct, [~l"usize", ~l"u1"]}
             } =
               Instruction.parse(
                 "add_with_overflow(struct { usize, u1 }, %96, @Air.Inst.Ref.one_usize)"
               )
    end

    alias Clr.Air.Instruction.Not

    test "not" do
      assert %Not{operand: {96, :keep}, type: ~l"usize"} = Instruction.parse("not(usize, %96)")
    end

    alias Clr.Air.Instruction.BitAnd

    test "bit_and" do
      assert %BitAnd{lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("bit_and(%96, %97)")
    end

    alias Clr.Air.Instruction.Rem

    test "rem" do
      assert %Rem{lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("rem(%96, %97)")
    end

    alias Clr.Air.Instruction.Min

    test "min" do
      assert %Min{lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("min(%96, %97)")
    end

    alias Clr.Air.Instruction.AddWrap

    test "add_wrap" do
      assert %AddWrap{lhs: {206, :clobber}, rhs: {207, :clobber}} =
               Instruction.parse("add_wrap(%206!, %207!)")
    end

    alias Clr.Air.Instruction.BoolOr

    test "bool_or" do
      assert %BoolOr{lhs: {96, :keep}, rhs: {97, :keep}} =
               Instruction.parse("bool_or(%96, %97)")
    end
  end

  describe "atomics" do
    alias Clr.Air.Instruction.AtomicRmw

    test "atomic_rmw" do
      assert %AtomicRmw{
               dst: {:literal, {:ptr, :one, ~l"u8"}, ~l"debug.panicking.raw"},
               mode: :seq_cst,
               op: :add,
               val: ~l"@Air.Inst.Ref.one_u8"
             } =
               Instruction.parse(
                 "atomic_rmw(<*u8, debug.panicking.raw>, @Air.Inst.Ref.one_u8, Add, seq_cst)"
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

  alias Clr.Air.Instruction.Arg

  test "arg" do
    assert %Arg{type: {:ptr, :many, ~l"usize"}, name: "argc_argv_ptr"} =
             Instruction.parse(~S/arg([*]usize, "argc_argv_ptr")/)
  end

  test "arg without value" do
    assert %Arg{type: {:ptr, :many, ~l"usize"}, name: nil} =
             Instruction.parse(~S/arg([*]usize)/)
  end
end
