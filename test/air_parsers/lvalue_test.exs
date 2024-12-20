defmodule ClrTest.AirParsers.LvalueTest do
  use ExUnit.Case, async: true

  import Clr.Air.Lvalue

  test "a basic identifier is an lvalue" do
    assert ~l"foo" = Clr.Air.Lvalue.parse("foo")
  end

  test "an identifier with a struct dereference is an lvalue" do
    assert ~l"foo.bar" = Clr.Air.Lvalue.parse("foo.bar")
  end

  test "an identifier with an array dereference is an lvalue" do
    assert {:lvalue, ["foo", 2]} = Clr.Air.Lvalue.parse("foo[2]")
  end

  test "an identifier with multi array dereference is an lvalue" do
    assert {:lvalue, ["foo", 2, 3]} = Clr.Air.Lvalue.parse("foo[2][3]")
  end

  test "the special (function *) identifier is an lvalue" do
    assert {:function, "write"} = Clr.Air.Lvalue.parse("(function 'write')")
  end

  describe "type-returning function call with a dereference" do
    test "called with integer" do
      assert {:lvalue, [{:comptime_call, ~l"foo", [1]}, "bar"]} =
               Clr.Air.Lvalue.parse("foo(1).bar")

      assert {:lvalue, [{:comptime_call, ~l"foo", [1]}, "bar", "baz"]} =
               Clr.Air.Lvalue.parse("foo(1).bar.baz")

      assert {:lvalue, [{:comptime_call, ~l"foo.bar", [1]}, "bar", "baz"]} =
               Clr.Air.Lvalue.parse("foo.bar(1).bar.baz")
    end

    test "called with an lvalue (whih might be a type)" do
      assert {:lvalue, [{:comptime_call, ~l"foo", [~l"foo.bar"]}, "bar"]} =
               Clr.Air.Lvalue.parse("foo(foo.bar).bar")
    end

    test "called with multiple parameters" do
      # note that the arguments in the "comptime call" don't have spaces
      assert {:lvalue, [{:comptime_call, ~l"foo", [1, ~l"bar.baz"]}, "bar"]} =
               Clr.Air.Lvalue.parse("foo(1,bar.baz).bar")
    end
  end
end
