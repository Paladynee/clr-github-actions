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
      assert {:ptr, :many, "i32", sentinel: "0"} = Type.parse("[*:0]i32")
    end

    test "slice pointer" do
      assert {:ptr, :slice, "i32", sentinel: "0"} = Type.parse("[:0]i32")
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

  test "const * function type" do
    assert {:fn, [], "noreturn", [callconv: :naked]} =
             Type.parse("*const fn () callconv(.naked) noreturn")
  end
end
