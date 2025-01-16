defmodule ClrTest.AirParsers.InstructionTest do
  use ExUnit.Case, async: true
  alias Clr.Air.Instruction

  import Clr.Air.Lvalue

  setup(do: {:ok, empty_map: %{}})

  describe "debug instructions" do
    alias Clr.Air.Instruction.DbgStmt

    test "dbg_stmt" do
      assert %DbgStmt{row: 9, col: 10} = Instruction.parse("dbg_stmt(9:10)")
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
      assert %DbgArgInline{val: {:literal, ~l"Target.Cpu.Arch", {:enum, "x86_64"}}, key: "arch"} =
               Instruction.parse("dbg_arg_inline(<Target.Cpu.Arch, .x86_64>, \"arch\")")
    end

    alias Clr.Air.Instruction.DbgVarVal

    test "dbg_var_val" do
      assert %DbgVarVal{src: {0, :keep}, val: "argc"} =
               Instruction.parse(~S/dbg_var_val(%0, "argc")/)

      # more complex case

      assert %DbgVarVal{} =
               Instruction.parse(
                 ~S/dbg_var_val(<?[*]*const fn () callconv(.c) void, @as([*]*const fn () callconv(.c) void, @ptrCast(__init_array_start))>, "opt_init_array_start")/
               )
    end

    alias Clr.Air.Instruction.DbgVarPtr

    test "dbg_var_ptr" do
      assert %DbgVarPtr{src: {0, :keep}, val: "envp_count"} =
               Instruction.parse(~S/dbg_var_ptr(%0, "envp_count")/)
    end
  end

  describe "control flow instructions" do
    alias Clr.Air.Instruction.Trap

    test "trap" do
      assert %Trap{} = Instruction.parse("trap()")
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

    alias Clr.Air.Instruction.Controls.Repeat

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

    alias Clr.Air.Instruction.RetLoad

    test "ret_load" do
      assert %RetLoad{val: {19, :keep}} = Instruction.parse("ret_load(%19)")
    end

    alias Clr.Air.Instruction.Try

    test "try" do
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

    alias Clr.Air.Instruction.TryPtr

    test "try_ptr" do
      assert %TryPtr{
               loc: {259, :keep},
               type:
                 {:ptr, :one, {:ptr, :slice, {:lvalue, ["u8"]}, [const: true]}, [const: true]},
               code: %{:clobbers => [5, 247, 248]},
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

    alias Clr.Air.Instruction.TryCold

    test "try_cold" do
      assert %TryCold{loc: {28, :keep}, error_code: %{}, clobbers: [28]} =
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

  describe "pointer operations" do
    alias Clr.Air.Instruction.PtrElemVal

    test "ptr_elem_val" do
      assert %PtrElemVal{src: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_usize"} =
               Instruction.parse("ptr_elem_val(%0, @Air.Inst.Ref.zero_usize)")
    end

    alias Clr.Air.Instruction.PtrElemPtr

    test "ptr_elem_ptr" do
      assert %PtrElemPtr{
               loc: {79, :keep},
               val: {:literal, ~l"usize", 13},
               type: {:ptr, :one, {:optional, ~l"debug.Dwarf.Section"}, []}
             } =
               Instruction.parse("ptr_elem_ptr(*?debug.Dwarf.Section, %79, <usize, 13>)")
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

    alias Clr.Air.Instruction.StructFieldPtrIndex

    test "struct_field_ptr_index_0" do
      assert %StructFieldPtrIndex{type: {:ptr, :one, ~l"u32", []}, src: {0, :keep}, index: 0} =
               Instruction.parse("struct_field_ptr_index_0(*u32, %0)")
    end

    test "struct_field_ptr_index_1" do
      assert %StructFieldPtrIndex{type: {:ptr, :one, ~l"u32", []}, src: {0, :keep}, index: 1} =
               Instruction.parse("struct_field_ptr_index_1(*u32, %0)")
    end

    test "struct_field_ptr_index_2" do
      assert %StructFieldPtrIndex{type: {:ptr, :one, ~l"u32", []}, src: {0, :keep}, index: 2} =
               Instruction.parse("struct_field_ptr_index_2(*u32, %0)")
    end

    test "struct_field_ptr_index_3" do
      assert %StructFieldPtrIndex{type: {:ptr, :one, ~l"u32", []}, src: {0, :keep}, index: 3} =
               Instruction.parse("struct_field_ptr_index_3(*u32, %0)")
    end

    alias Clr.Air.Instruction.WrapOptional

    test "wrap_optional" do
      assert %WrapOptional{type: {:optional, ~l"usize"}, src: {0, :keep}} =
               Instruction.parse("wrap_optional(?usize, %0)")
    end

    alias Clr.Air.Instruction.FrameAddr

    test "frame_addr" do
      assert %FrameAddr{} = Instruction.parse("frame_addr()")
    end

    alias Clr.Air.Instruction.PtrSlicePtrPtr

    test "ptr_slice_ptr_ptr" do
      assert %PtrSlicePtrPtr{
               type: {:ptr, :slice, {:ptr, :one, ~l"u8", []}, []},
               src: {13, :clobber}
             } =
               Instruction.parse("ptr_slice_ptr_ptr([]*u8, %13!)")
    end

    alias Clr.Air.Instruction.PtrSliceLenPtr

    test "ptr_slice_len_ptr" do
      assert %PtrSliceLenPtr{type: {:ptr, :one, {:lvalue, ["usize"]}, []}, src: {20, :clobber}} =
               Instruction.parse("ptr_slice_len_ptr(*usize, %20!)")
    end

    alias Clr.Air.Instruction.UnwrapErrunionErrPtr

    test "unwrap_errunion_err_ptr" do
      assert %UnwrapErrunionErrPtr{
               type: {:errorset, ~w[InvalidBuffer EndOfBuffer Overflow]},
               src: {259, :clobber}
             } =
               Instruction.parse(
                 "unwrap_errunion_err_ptr(error{Overflow,EndOfBuffer,InvalidBuffer}, %259!)"
               )
    end
  end

  describe "memory operations" do
    alias Clr.Air.Instruction.Alloc

    test "alloc" do
      assert %Alloc{type: {:ptr, :one, ~l"usize", []}} = Instruction.parse("alloc(*usize)")
    end

    alias Clr.Air.Instruction.Store

    test "store" do
      assert %Store{val: ~l"@Air.Inst.Ref.zero_usize", loc: {19, :keep}} =
               Instruction.parse("store(%19, @Air.Inst.Ref.zero_usize)")
    end

    alias Clr.Air.Instruction.Load

    test "load" do
      assert %Load{type: {:ptr, :many, ~l"usize", []}, loc: {19, :keep}} =
               Instruction.parse("load([*]usize, %19)")
    end

    alias Clr.Air.Instruction.OptionalPayload

    test "optional_payload" do
      assert %OptionalPayload{type: ~l"void", loc: {19, :keep}} =
               Instruction.parse("optional_payload(void, %19)")
    end

    alias Clr.Air.Instruction.OptionalPayloadPtr

    test "optional_payload_ptr" do
      assert %OptionalPayloadPtr{
               type: {:ptr, :one, {:lvalue, ["debug", "SelfInfo"]}, []},
               loc:
                 {:literal, {:ptr, :one, {:optional, {:lvalue, ["debug", "SelfInfo"]}}, []},
                  {:lvalue, ["debug", "self_debug_info"]}}
             } =
               Instruction.parse(
                 "optional_payload_ptr(*debug.SelfInfo, <*?debug.SelfInfo, debug.self_debug_info>)"
               )
    end

    alias Clr.Air.Instruction.OptionalPayloadPtrSet

    test "optional_payload_ptr_set" do
      assert %OptionalPayloadPtrSet{
               type: {:ptr, :one, {:lvalue, ["debug", "SelfInfo"]}, []},
               loc:
                 {:literal, {:ptr, :one, {:optional, {:lvalue, ["debug", "SelfInfo"]}}, []},
                  {:lvalue, ["debug", "self_debug_info"]}}
             } =
               Instruction.parse(
                 "optional_payload_ptr_set(*debug.SelfInfo, <*?debug.SelfInfo, debug.self_debug_info>)"
               )
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

    alias Clr.Air.Instruction.UnionInit

    test "union_init" do
      assert %UnionInit{src: {18, :clobber}, val: 0} = Instruction.parse("union_init(0, %18!)")
    end

    alias Clr.Air.Instruction.UnwrapErrunionPayload

    test "unwrap_errunion_payload" do
      assert %UnwrapErrunionPayload{type: ~l"usize", src: {0, :keep}} =
               Instruction.parse("unwrap_errunion_payload(usize, %0)")
    end

    alias Clr.Air.Instruction.UnwrapErrunionErr

    test "unwrap_errunion_err" do
      assert %UnwrapErrunionErr{type: {:errorset, ["Unexpected"]}, src: {0, :keep}} =
               Instruction.parse("unwrap_errunion_err(error{Unexpected}, %0)")
    end

    alias Clr.Air.Instruction.Intcast

    test "intcast" do
      assert %Intcast{type: ~l"usize", src: {0, :keep}} =
               Instruction.parse("intcast(usize, %0)")
    end

    alias Clr.Air.Instruction.Trunc

    test "trunc" do
      assert %Trunc{type: ~l"usize", src: {0, :keep}} =
               Instruction.parse("trunc(usize, %0)")
    end

    alias Clr.Air.Instruction.Memset

    test "memset" do
      assert %Memset{loc: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_u8"} =
               Instruction.parse("memset(%0, @Air.Inst.Ref.zero_u8)")
    end

    alias Clr.Air.Instruction.MemsetSafe

    test "memset_safe" do
      assert %MemsetSafe{loc: {0, :keep}, val: ~l"@Air.Inst.Ref.zero_u8"} =
               Instruction.parse("memset_safe(%0, @Air.Inst.Ref.zero_u8)")
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
      assert %ArrayToSlice{type: {:ptr, :slice, ~l"u8", []}, src: {13, :clobber}} =
               Instruction.parse("array_to_slice([]u8, %13!)")
    end

    alias Clr.Air.Instruction.ArrayElemVal

    test "array_elem_val" do
      assert %ArrayElemVal{type: {:literal, {:array, 2, _, []}, _}, src: {519, :keep}} =
               Instruction.parse(
                 "array_elem_val(<[2]debug.Dwarf.Section.Id, .{ .eh_frame, .debug_frame }>, %519)"
               )
    end

    alias Clr.Air.Instruction.SetUnionTag

    test "set_union_tag" do
      assert %SetUnionTag{loc: {14, :keep}, val: {:literal, _, _}} =
               Instruction.parse(
                 "set_union_tag(%14, <@typeInfo(debug.Dwarf.readEhPointer__union_4486).@\"union\".tag_type.?, .unsigned>)"
               )
    end

    alias Clr.Air.Instruction.GetUnionTag

    test "get_union_tag" do
      assert %GetUnionTag{loc: {298, :keep}, type: {:lvalue, _}} =
               Instruction.parse(
                 "get_union_tag(@typeInfo(debug.Dwarf.readEhPointer__union_4486).@\"union\".tag_type.?, %298)"
               )
    end

    alias Clr.Air.Instruction.ErrunionPayloadPtrSet

    test "errunion_payload_ptr_set" do
      assert %ErrunionPayloadPtrSet{
               type: {:ptr, :one, ~l"debug.Dwarf.EntryHeader", []},
               loc: {0, :keep}
             } =
               Instruction.parse("errunion_payload_ptr_set(*debug.Dwarf.EntryHeader, %0)")
    end

    alias Clr.Air.Instruction.IntFromBool

    test "int_from_bool" do
      assert %IntFromBool{val: {218, :clobber}} = Instruction.parse("int_from_bool(%218!)")
    end

    alias Clr.Air.Instruction.ErrorName

    test "error_name" do
      assert %ErrorName{val: {39, :clobber}} = Instruction.parse("error_name(%39!)")
    end

    alias Clr.Air.Instruction.TagName

    test "tag_name" do
      assert %TagName{val: {39, :clobber}} = Instruction.parse("tag_name(%39!)")
    end
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

    alias Clr.Air.Instruction.Reduce

    test "reduce" do
      assert %Reduce{loc: {0, :keep}, op: :or} =
               Instruction.parse("reduce(%0, Or)")
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
