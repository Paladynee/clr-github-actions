defmodule ClrTest.Air.LiteralTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Literal
  import Clr.Air.Lvalue

  test "integer literal" do
    assert {:literal, ~l"usize", 8} = Literal.parse("<usize, 8>")
  end

  test "negative integer literal" do
    assert {:literal, ~l"usize", -8} = Literal.parse("<usize, -8>")
  end

  test "literal with an enum literal" do
    assert {:literal, ~l"Target.Cpu.Arch", {:enum, "x86_64"}} =
             Literal.parse("<Target.Cpu.Arch, .x86_64>")
  end

  test "generic function literal" do
    assert {:literal, {:fn, [{:ptr, :slice, ~l"elf.Elf64_Phdr", []}], ~l"void", []},
            {:function, "initStatic"}} =
             Literal.parse("<fn ([]elf.Elf64_Phdr) void, (function 'initStatic')>")
  end

  test "const * function literal" do
    assert {:literal, {:fn, [], ~l"noreturn", [callconv: :naked]}, ~l"start._start"} =
             Literal.parse("<*const fn () callconv(.naked) noreturn, start._start>")
  end

  test "with @as and @ptrCast" do
    assert {:literal, _, {:as, _, _}} =
             Literal.parse(
               "<?[*]*const fn () callconv(.c) void, @as([*]*const fn () callconv(.c) void, @ptrCast(__init_array_start))>"
             )
  end

  test "complex function literal" do
    assert {:literal, {:fn, [~l"usize", _, _], ~l"u8", [callconv: :inline]},
            {:function, "callMainWithArgs"}} =
             Literal.parse(
               "<fn (usize, [*][*:0]u8, [][*:0]u8) callconv(.@\"inline\") u8, (function 'callMainWithArgs')>"
             )
  end

  test "function literal with error union type" do
    assert {:literal, {:fn, _, {:errorable, _, _}, []}, {:function, "getrlimit"}} =
             Literal.parse(
               "<fn (os.linux.rlimit_resource__enum_2617) error{Unexpected}!os.linux.rlimit, (function 'getrlimit')>"
             )
  end

  test "map literal" do
    assert {:literal, ~l"os.linux.MAP__struct_2035", {:struct, _}} =
             Literal.parse(
               "<os.linux.MAP__struct_2035, .{ .TYPE = .PRIVATE, .FIXED = false, .ANONYMOUS = true, .@\"32BIT\" = false, ._7 = 0, .GROWSDOWN = false, ._9 = 0, .DENYWRITE = false, .EXECUTABLE = false, .LOCKED = false, .NORESERVE = false, .POPULATE = false, .NONBLOCK = false, .STACK = false, .HUGETLB = false, .SYNC = false, .FIXED_NOREPLACE = false, ._21 = 0, .UNINITIALIZED = false, .@\"_\" = 0 }>"
             )
  end

  test "string literal without index" do
    assert {:literal, {:ptr, :one, {:array, 15, ~l"u8", sentinel: 0}, [const: true]},
            {:string, "(msg truncated)"}} =
             Literal.parse("<*const [15:0]u8, \"(msg truncated)\">")
  end

  test "string literal with index" do
    assert {:literal, {:ptr, :slice, ~l"u8", [const: true]},
            {:substring, "integer overflow", 0..16}} =
             Literal.parse("<[]const u8, \"integer overflow\"[0..16]>")
  end

  test "pointer literal with struct dereferencing" do
    assert {:literal, {:ptr, :one, ~l"os.linux.Sigaction", [const: true]},
            {
              :structptr,
              {:struct, _}
            }} =
             Literal.parse(
               "<*const os.linux.Sigaction, &.{ .handler = .{ .handler = start.noopSigHandler }, .mask = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, .flags = 0, .restorer = null }>"
             )
  end

  test "literal with at/ptrcast inside the struct" do
    assert {:literal, ~l"os.linux.Sigaction",
            {:struct, [{"handler", {:as, {:ptr, :one, ~l"foo", []}, {:ptrcast, ~l"debug.foo"}}}]}} =
             Literal.parse("<os.linux.Sigaction, .{ .handler = @as(*foo, @ptrCast(debug.foo)) }>")
  end

  test "strange literal" do
    assert {:literal, {:ptr, :slice, ~l"u8", [const: true]}, {:structptr, {:struct, []}, 0..0}} =
             Literal.parse("<[]const u8, &.{}[0..0]>")
  end

  test "sizeof allowed in literals" do
    assert {:literal, ~l"usize", {:sizeof, ~l"os.linux.tls.AbiTcb__struct_2928"}} =
             Literal.parse("<usize, @sizeOf(os.linux.tls.AbiTcb__struct_2928)>")
  end

  test "alignof allowed in literals" do
    assert {:literal, ~l"usize", {:alignof, ~l"os.linux.tls.AbiTcb__struct_2928"}} =
             Literal.parse("<usize, @alignOf(os.linux.tls.AbiTcb__struct_2928)>")
  end

  test "dereferenced literal value" do
    assert {:literal, {:fn, _args, _, []}, {:lvalue, _}} =
             Literal.parse(
               "<*const fn (*const anyopaque, []const u8) anyerror!usize, io.GenericWriter(fs.File,error{Unexpected,DiskQuota,FileTooBig,InputOutput,NoSpaceLeft,DeviceBusy,InvalidArgument,AccessDenied,BrokenPipe,SystemResources,OperationAborted,NotOpenForWriting,LockViolation,WouldBlock,ConnectionResetByPeer,ProcessNotFound},(function 'write')).typeErasedWriteFn>"
             )
  end

  test "void value" do
    assert {:literal, {:errorable, ~w[LimitTooBig PermissionDenied Unexpected], ~l"void"}, :void} =
             Literal.parse("<error{Unexpected,PermissionDenied,LimitTooBig}!void, {}>")
  end

  test "another function literal" do
    assert {:literal, {:fn, [~l"io.Writer", {:struct, [~l"u32"]}], {:errorable, _, ~l"void"}, []},
            {:function, "format__anon_3497"}} =
             Literal.parse(
               "<fn (io.Writer, struct { u32 }) @typeInfo(@typeInfo(@TypeOf(fmt.format__anon_3497)).@\"fn\".return_type.?).error_union.error_set!void, (function 'format__anon_3497')>"
             )
  end

  test "literal with volatile pointer" do
    assert {:literal, _, {:ptr_deref, _}} =
             Literal.parse(
               "<*allowzero volatile u8, @as(*allowzero volatile u8, @ptrFromInt(0)).*>"
             )
  end

  test "elided struct literal" do
    assert {:literal, ~l"debug.SelfInfo.Struct", {:struct, [:...]}} = Literal.parse("<debug.SelfInfo.Struct, .{ ... }>")
  end
end
