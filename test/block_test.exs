defmodule ClrTest.BlockTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Function
  alias Clr.Block

  import Clr.Air.Lvalue

  describe "for the put_type/3,4 function" do
    test "we can put a basic type and no metadata are added" do
      slots = %{47 => {~l"foo.type", %{}}}
      assert %{slots: ^slots} =
        %Function{name: ~l"foo.bar"}
        |> Block.new([])
        |> Block.put_type(47, ~l"foo.type")
    end

    test "metadata can be added too" do
      slots = %{47 => {~l"foo.type", %{foo: :bar}}}

      assert %{slots: ^slots} =
        %Function{name: ~l"foo.bar"}
        |> Block.new([])
        |> Block.put_type(47, ~l"foo.type", foo: :bar)
    end
  end

  describe "the put_meta/3 function" do
    test "can be used to add metadata to an existing slot" do
      slots = %{47 => {~l"foo.type", %{foo: :bar}}}

      %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Block.put_type(47, ~l"foo.type")
      |> Block.put_meta(47, foo: :bar)
    end
  end

  describe "the put_await/3 function" do
    test "can be used to add an await to a block" do
      ref = make_ref()
      awaits = %{47 => ref}

      assert %{awaits: ^awaits} = %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Block.put_await(47, ref)
    end
  end

  describe "the fetch_up! function" do
    test "can be used to retrieve a stored type/meta tuple" do
      block = %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Block.put_type(47, ~l"foo.type", foo: :bar)

      assert {{~l"foo.type", %{foo: :bar}}, %Block{}} = Block.fetch_up!(block, 47)
    end

    test "can be used to retrieve awaited information, which can arbitrarily alter the block" do
      future = make_ref()

      block = %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Block.put_await(47, future)

      send(self(), {future, {~l"bar.baz", &Block.put_type(&1, 48, ~l"bar.quux")}})

      assert {{~l"bar.baz", _}, %{slots: %{48 => {~l"bar.quux", _}}}} = Block.fetch_up!(block, 47)
    end
  end
end
