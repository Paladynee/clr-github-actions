defmodule ClrTest.AirParsers.BaseTest do
  use ExUnit.Case, async: true

  import NimbleParsec

  defparsec(:name, parsec({Clr.Air.Base, :name}))

  defmacrop assert_parses(expr) do
    quote do
      assert {:ok, _result, "", _, _, _} = unquote(expr)
    end
  end

  test "name" do
    assert_parses(name("foo"))
  end

  test "camel cased" do
    assert_parses(name("fooBar"))
  end

  test "with alphanumeric" do
    assert_parses(name("foo123"))
  end

  test "with namespace" do
    assert_parses(name("foo.bar"))
  end

  test "with deep namespace" do
    assert_parses(name("foo.bar.baz"))
  end

  test "with indices" do
    assert_parses(name("foo[1]"))
  end

  test "with multiple indices" do
    assert_parses(name("foo[1][2]"))
  end

  test "with namespaced indices" do
    assert_parses(name("foo.bar[1]"))
  end

  test "with namespaces and indices" do
    assert_parses(name("foo.bar[1].baz[2]"))
  end

  test "with a leading @ symbol" do
    assert_parses(name("@foo"))
  end

  test "with a leading . symbol" do
    assert_parses(name(".foo"))
  end
end
