defmodule ClrTest.AirParsers.LvalueTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Lvalue
  import Lvalue

  test "a basic identifier is an lvalue" do
    assert ~l"foo" = Lvalue.parse("foo")
  end

  test "an identifier with a struct dereference is an lvalue" do
    assert ~l"foo.bar" = Lvalue.parse("foo.bar")
  end

  test "an identifier with an array dereference is an lvalue" do
    assert {:lvalue, ["foo", 2]} = Lvalue.parse("foo[2]")
  end

  test "an identifier with multi array dereference is an lvalue" do
    assert {:lvalue, ["foo", 2, 3]} = Lvalue.parse("foo[2][3]")
  end

  test "the special (function *) identifier is an lvalue" do
    assert {:function, "write"} = Lvalue.parse("(function 'write')")
  end

  describe "type-returning function call with a dereference" do
    test "called with integer" do
      assert {:lvalue, [{:comptime_call, ~l"foo", [1]}, "bar"]} =
               Lvalue.parse("foo(1).bar")

      assert {:lvalue, [{:comptime_call, ~l"foo", [1]}, "bar", "baz"]} =
               Lvalue.parse("foo(1).bar.baz")

      assert {:lvalue, [{:comptime_call, ~l"foo.bar", [1]}, "bar", "baz"]} =
               Lvalue.parse("foo.bar(1).bar.baz")
    end

    test "called with an lvalue (whih might be a type)" do
      assert {:lvalue, [{:comptime_call, ~l"foo", [~l"foo.bar"]}, "bar"]} =
               Lvalue.parse("foo(foo.bar).bar")
    end

    test "called with multiple parameters" do
      # note that the arguments in the "comptime call" don't have spaces
      assert {:lvalue, [{:comptime_call, ~l"foo", [1, ~l"bar.baz"]}, "bar"]} =
               Lvalue.parse("foo(1,bar.baz).bar")
    end
  end

  test "with a question mark" do
    assert {:lvalue, ["foo", :unwrap_optional]} = Lvalue.parse("foo.?")
  end

  test "with a star" do
    assert {:lvalue, ["foo", :pointer_deref]} = Lvalue.parse("foo.*")
  end

  test "with a comptime struct as a passed parameter to a function" do
    assert {:lvalue, [{:comptime_call, _, _}]} = Lvalue.parse("debug.Dwarf.expression.StackMachine(.{ .addr_size = 8, .endian = .little, .call_frame_context = true })")
  end
end
