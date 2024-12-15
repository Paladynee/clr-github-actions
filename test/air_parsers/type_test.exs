defmodule ClrTest.Air.TypeTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Type

  test "basic type" do
    assert "i32" = Type.parse("i32")
  end

  describe "basic pointer types" do
    test "single pointer" do
      assert {:ptr, :one, "i32"} = Type.parse("*i32")
    end

    test "many pointer" do
      assert {:ptr, :many, "i32"} = Type.parse("[*]i32")
    end

    test "slice pointer" do
      assert {:ptr, :slice, "i32"} = Type.parse("[]i32")
    end
  end

  describe "sentinel pointer types" do
    test "manypointer" do
      assert {:ptr, :many, "i32", sentinel: 0} = Type.parse("[*:0]i32")
    end

    test "slice pointer" do
      assert {:ptr, :slice, "i32", sentinel: 0} = Type.parse("[:0]i32")
    end
  end

  describe "const pointer types" do
    test "single pointer" do
      assert {:ptr, :one, "i32", const: true} = Type.parse("*const i32")
    end

    test "many pointer" do
      assert {:ptr, :many, "i32", const: true} = Type.parse("[*]const i32")
    end

    test "slice pointer" do
      assert {:ptr, :slice, "i32", const: true} = Type.parse("[]const i32")
    end
  end

  describe "optional pointer types" do
    test "single pointer" do
      assert {:ptr, :one, "i32", optional: true} = Type.parse("?*i32")
    end

    test "const pointer" do
      assert {:ptr, :one, "i32", opts} = Type.parse("?*const i32")
      assert opts[:optional]
      assert opts[:const]
    end

    test "pointer to a function" do
      assert {:ptr, :many, {:fn, [], "void", [callconv: :c]}} =
               Type.parse("[*]*const fn () callconv(.c) void")
    end
  end

  test "optional generic type" do
    assert {:optional, "i32"} = Type.parse("?i32")
  end

  test "function pointer type with callconv" do
    assert {:ptr, :many, {:fn, [], "void", [callconv: :c]}} =
             Type.parse("[*]*const fn () callconv(.c) void")
  end

  test "function type with callconv" do
    assert {:fn, ["Target.Cpu.Arch"], "bool", [callconv: :inline]} =
             Type.parse("fn (Target.Cpu.Arch) callconv(.@\"inline\") bool")
  end

  test "function type with noalias" do
    assert {:fn, [{:noalias, {:ptr, :one, "usize"}}, {:noalias, {:ptr, :one, "u8"}}], "u8", []} =
             Type.parse("fn (noalias *usize, noalias *u8) u8")
  end

  test "const * function type" do
    assert {:fn, [], "noreturn", [callconv: :naked]} =
             Type.parse("*const fn () callconv(.naked) noreturn")
  end

  test "array type" do{:literal, "usize", {:sizeof, "os.linux.tls.AbiTcb__struct_2928"}}
    assert {:array, 8, "i32"} = Type.parse("[8]i32")
  end

  test "aligned slice type" do
    assert {:ptr, :slice, "u8", alignment: 4096} = Type.parse("[]align(4096) u8")
  end

  test "enum literal type" do
    assert :enum_literal = Type.parse("@Type(.enum_literal)")
  end

  test "comptime" do
    assert {:comptime, :enum_literal} = Type.parse("comptime @Type(.enum_literal)")
  end

  test "anonymous struct type" do
    assert {:struct, ["u32", "u1"]} = Type.parse("struct { u32, u1 }")
  end

  test "error type" do
    assert {:errorable, ["Unexpected"], "os.linux.rlimit"} =
             Type.parse("error{Unexpected}!os.linux.rlimit")
  end

  test "error union type" do
    assert {:errorunion, ["Invalid", "Unexpected"]} =
             Type.parse("error{Unexpected,Invalid}")
  end
end
