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
    assert {:literal, ~l"Target.Cpu.Arch", {:enum, ~l"x86_64"}} = Literal.parse("<Target.Cpu.Arch, .x86_64>")
  end

  test "generic function literal" do
    assert {:literal, {:fn, [{:ptr, :slice, ~l"elf.Elf64_Phdr"}], ~l"void", []},
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

  test "string literal" do
    assert {:literal, {:ptr, :slice, ~l"u8", [const: true]}, {:string, "integer overflow", 0..16}} =
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
end
