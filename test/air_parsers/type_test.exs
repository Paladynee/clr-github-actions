defmodule ClrTest.Air.TypeTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Type

  import Clr.Air.Lvalue

  test "basic type" do
    assert ~l"i32" = Type.parse("i32")
  end

  describe "basic pointer types" do
    test "single pointer" do
      assert {:ptr, :one, ~l"i32", []} = Type.parse("*i32")
    end

    test "many pointer" do
      assert {:ptr, :many, ~l"i32", []} = Type.parse("[*]i32")
    end

    test "slice pointer" do
      assert {:ptr, :slice, ~l"i32", []} = Type.parse("[]i32")
    end
  end

  describe "special pointer augmentations" do
    test "allowzero" do
      assert {:ptr, :one, ~l"i32", allowzero: true} = Type.parse("*allowzero i32")
    end

    test "volatile" do
      assert {:ptr, :one, ~l"i32", volatile: true} = Type.parse("*volatile i32")
    end
  end

  describe "sentinel pointer types" do
    test "manypointer" do
      assert {:ptr, :many, ~l"i32", sentinel: 0} = Type.parse("[*:0]i32")
    end

    test "slice pointer" do
      assert {:ptr, :slice, ~l"i32", sentinel: 0} = Type.parse("[:0]i32")
    end
  end

  describe "const pointer types" do
    test "single pointer" do
      assert {:ptr, :one, ~l"i32", const: true} = Type.parse("*const i32")
    end

    test "many pointer" do
      assert {:ptr, :many, ~l"i32", const: true} = Type.parse("[*]const i32")
    end

    test "slice pointer" do
      assert {:ptr, :slice, ~l"i32", const: true} = Type.parse("[]const i32")
    end
  end

  describe "optional pointer types" do
    test "single pointer" do
      assert {:ptr, :one, ~l"i32", optional: true} = Type.parse("?*i32")
    end

    test "const pointer" do
      assert {:ptr, :one, ~l"i32", opts} = Type.parse("?*const i32")
      assert opts[:optional]
      assert opts[:const]
    end

    test "pointer to a function" do
      assert {:ptr, :many, {:fn, [], ~l"void", [callconv: :c]}, []} =
               Type.parse("[*]*const fn () callconv(.c) void")
    end
  end

  test "optional generic type" do
    assert {:optional, ~l"i32"} = Type.parse("?i32")
  end

  test "function pointer type with callconv" do
    assert {:ptr, :many, {:fn, [], ~l"void", [callconv: :c]}, []} =
             Type.parse("[*]*const fn () callconv(.c) void")
  end

  test "function type with callconv" do
    assert {:fn, [~l"Target.Cpu.Arch"], ~l"bool", [callconv: :inline]} =
             Type.parse("fn (Target.Cpu.Arch) callconv(.@\"inline\") bool")
  end

  test "function type with noalias" do
    assert {:fn, [{:noalias, {:ptr, :one, ~l"usize", []}}, {:noalias, {:ptr, :one, ~l"u8", []}}],
            ~l"u8",
            []} =
             Type.parse("fn (noalias *usize, noalias *u8) u8")
  end

  test "const * function type" do
    assert {:fn, [], ~l"noreturn", [callconv: :naked]} =
             Type.parse("*const fn () callconv(.naked) noreturn")
  end

  test "array type" do
    assert {:array, 8, ~l"i32", []} = Type.parse("[8]i32")
  end

  test "array type with sentinel" do
    assert {:array, 8, ~l"i32", sentinel: 0} = Type.parse("[8:0]i32")
  end

  test "aligned slice type" do
    assert {:ptr, :slice, ~l"u8", alignment: 4096} = Type.parse("[]align(4096) u8")
  end

  test "enum literal type" do
    assert :enum_literal = Type.parse("@Type(.enum_literal)")
  end

  test "comptime" do
    assert {:comptime, :enum_literal} = Type.parse("comptime @Type(.enum_literal)")
  end

  test "anonymous struct type" do
    assert {:struct, [~l"u32", ~l"u1"]} = Type.parse("struct { u32, u1 }")
  end

  test "error type" do
    assert {:errorable, ["Unexpected"], ~l"os.linux.rlimit"} =
             Type.parse("error{Unexpected}!os.linux.rlimit")
  end

  test "anyerror type" do
    assert {:errorable, :any, ~l"os.linux.rlimit"} =
             Type.parse("anyerror!os.linux.rlimit")
  end

  test "error union type" do
    assert {:errorset, ["Invalid", "Unexpected"]} =
             Type.parse("error{Unexpected,Invalid}")
  end

  test "lvalue error union type" do
    assert {:errorable, ~l"foo.bar", ~l"baz"} =
             Type.parse("foo.bar!baz")
  end

  test "atomic value allowed as function call" do
    assert {:lvalue, [{:comptime_call, ~l"atomic.Value", [~l"u8"]}]} =
             Type.parse("atomic.Value(u8)")
  end

  test "generic comptime function call type" do
    assert {:lvalue,
            [
              {:comptime_call, ~l"io.GenericWriter",
               [~l"fs.File", {:errorset, _}, {:function, "write"}]}
            ]} =
             Type.parse(
               "io.GenericWriter(fs.File,error{Unexpected,DiskQuota,FileTooBig,InputOutput,NoSpaceLeft,DeviceBusy,InvalidArgument,AccessDenied,BrokenPipe,SystemResources,OperationAborted,NotOpenForWriting,LockViolation,WouldBlock,ConnectionResetByPeer,ProcessNotFound},(function 'write'))"
             )
  end

  test "typeinfo call (call with dereference)" do
    assert {:lvalue, [{:comptime_call, ~l"@typeInfo", [~l"foo"]}, "child"]} =
             Type.parse("@typeInfo(foo).child")
  end

  test "complex generic type" do
    assert {:lvalue,
            [
              {:comptime_call, ~l"@typeInfo",
               [{:lvalue, [{:comptime_call, ~l"@TypeOf", [~l"fmt.format__anon_3497"]}]}]},
              "return_type",
              :unwrap_optional
            ]} = Type.parse("@typeInfo(@TypeOf(fmt.format__anon_3497)).return_type.?")
  end

  test "nested pointer type" do
    assert {:ptr, :many, {:ptr, :many, {:lvalue, ["u8"]}, [sentinel: 0]}, []} =
             Type.parse("[*][*:0]u8")
  end
end
