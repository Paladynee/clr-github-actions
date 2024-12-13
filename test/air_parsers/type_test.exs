defmodule ClrTest.Air.TypeTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Type

  test "basic type" do
    assert ["i32"] = Type.parse("i32")
  end

  describe "basic pointer types" do
    test "single pointer" do
      assert [{:ptr, :one, "i32"}] = Type.parse("*i32")
    end

    test "many pointer" do
      assert [{:ptr, :many, "i32"}] = Type.parse("[*]i32")
    end

    test "slice pointer" do
      assert [{:ptr, :slice, "i32"}] = Type.parse("[]i32")
    end
  end

  describe "sentinel pointer types" do
    test "manypointer" do
      assert [{:ptr, :many, "i32", sentinel: "0"}] = Type.parse("[*:0]i32")
    end

    test "slice pointer" do
      assert [{:ptr, :slice, "i32", sentinel: "0"}] = Type.parse("[:0]i32")
    end
  end

  describe "const pointer types" do
    test "single pointer" do
      assert [{:ptr, :one, "i32", const: true}] = Type.parse("*const i32")
    end

    test "many pointer" do
      assert [{:ptr, :many, "i32", const: true}] = Type.parse("[*]const i32")
    end

    test "slice pointer" do
      assert [{:ptr, :slice, "i32", const: true}] = Type.parse("[]const i32")
    end
  end

  describe "optional pointer types" do
    test "single pointer" do
      assert [{:ptr, :one, "i32", optional: true}] = Type.parse("?*i32")
    end

    test "const pointer" do
      assert [{:ptr, :one, "i32", opts}] = Type.parse("?*const i32")
      assert opts[:optional]
      assert opts[:const]
    end
  end

  test "optional generic type" do
    assert [{:optional, "i32"}] = Type.parse("?i32")
  end

  test "function types"
end
