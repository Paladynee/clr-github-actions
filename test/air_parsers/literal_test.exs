defmodule ClrTest.Air.LiteralTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Type

  test "generic literal"

  test "integer literal" do
    assert {:literal, "usize", 8} = Type.parse_literal("<usize, 8>")
  end

  test "negative integer literal" do
    assert {:literal, "usize", -8} = Type.parse_literal("<usize, -8>")
  end

  test "generic function literal" do
    assert {:literal, {:fn, [{:ptr, :slice, "elf.Elf64_Phdr"}], "void", []},
            {:function, "initStatic"}} =
             Type.parse_literal("<fn ([]elf.Elf64_Phdr) void, (function 'initStatic')>")
  end

  test "const * function literal" do
    assert {:literal, {:fn, [], "noreturn", [callconv: :naked]}, "start._start"} =
             Type.parse_literal("<*const fn () callconv(.naked) noreturn, start._start>")
  end

  test "with @as and @ptrCast" do
    assert {:literal, _, {:as, _, _}} =
             Type.parse_literal(
               "<?[*]*const fn () callconv(.c) void, @as([*]*const fn () callconv(.c) void, @ptrCast(__init_array_start))>"
             )
  end

  test "complex function literal" do
    assert {:literal, {:fn, ["usize", _, _], "u8", [callconv: :inline]},
            {:function, "callMainWithArgs"}} =
             Type.parse_literal(
               "<fn (usize, [*][*:0]u8, [][*:0]u8) callconv(.@\"inline\") u8, (function 'callMainWithArgs')>"
             )
  end

  test "function literal with error union type" do
    assert {:literal, {:fn, _, {:errorable, _, _}, []}, {:function, "getrlimit"}} =
             Type.parse_literal(
               "<fn (os.linux.rlimit_resource__enum_2617) error{Unexpected}!os.linux.rlimit, (function 'getrlimit')>"
             )
  end

  test "map literal" do
    assert {:literal, "os.linux.MAP__struct_2035", {:map, _}} =
             Type.parse_literal(
               "<os.linux.MAP__struct_2035, .{ .TYPE = .PRIVATE, .FIXED = false, .ANONYMOUS = true, .@\"32BIT\" = false, ._7 = 0, .GROWSDOWN = false, ._9 = 0, .DENYWRITE = false, .EXECUTABLE = false, .LOCKED = false, .NORESERVE = false, .POPULATE = false, .NONBLOCK = false, .STACK = false, .HUGETLB = false, .SYNC = false, .FIXED_NOREPLACE = false, ._21 = 0, .UNINITIALIZED = false, .@\"_\" = 0 }>"
             )
  end

  test "string literal" do
    assert {:literal, {:ptr, :slice, "u8", [const: true]}, {:string, "integer overflow", 0..16}} =
             Type.parse_literal("<[]const u8, \"integer overflow\"[0..16]>")
  end

  test "pointer literal with struct dereferencing" do
    assert {:literal, {:ptr, :one, "os.linux.Sigaction", [const: true]},
            {
              :structptr,
              ".{ .handler = .{ .handler = start.noopSigHandler }, .mask = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, .flags = 0, .restorer = null }"
            }} =
             Type.parse_literal(
               "<*const os.linux.Sigaction, &.{ .handler = .{ .handler = start.noopSigHandler }, .mask = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, .flags = 0, .restorer = null }>"
             )
  end

  test "strange literal" do
    assert {:literal, {:ptr, :slice, "u8", [const: true]}, {:structptr, ".{}0..0"}} =
             Type.parse_literal("<[]const u8, &.{}[0..0]>")
  end

  test "sizeof allowed in literals" do
    assert {:literal, "usize", {:sizeof, "os.linux.tls.AbiTcb__struct_2928"}} =
             Type.parse_literal("<usize, @sizeOf(os.linux.tls.AbiTcb__struct_2928)>")
  end

  test "alignof allowed in literals" do
    assert {:literal, "usize", {:alignof, "os.linux.tls.AbiTcb__struct_2928"}} =
             Type.parse_literal("<usize, @alignOf(os.linux.tls.AbiTcb__struct_2928)>")
  end

  test "dereferenced literal value" do
    assert {:literal, :foo, :bar} = Type.parse_literal("<*const fn (*const anyopaque, []const u8) anyerror!usize, io.GenericWriter(fs.File,error{Unexpected,DiskQuota,FileTooBig,InputOutput,NoSpaceLeft,DeviceBusy,InvalidArgument,AccessDenied,BrokenPipe,SystemResources,OperationAborted,NotOpenForWriting,LockViolation,WouldBlock,ConnectionResetByPeer,ProcessNotFound},(function 'write')).typeErasedWriteFn>")
  end
end
