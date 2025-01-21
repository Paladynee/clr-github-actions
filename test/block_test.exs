defmodule ClrTest.BlockTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Function
  alias Clr.Block

  import Clr.Air.Lvalue

  describe "for the put_type/3,4 function" do
    test "we can put a basic type and no metadata are added" do
      slots = %{47 => {:u, 32, %{}}}

      assert %{slots: ^slots} =
               %Function{name: ~l"foo.bar"}
               |> Block.new([])
               |> Block.put_type(47, {:u, 32, %{}})
    end

    test "metadata can be added too" do
      slots = %{47 => {:u, 32, %{foo: :bar}}}

      assert %{slots: ^slots} =
               %Function{name: ~l"foo.bar"}
               |> Block.new([])
               |> Block.put_type(47, {:u, 32, %{}}, foo: :bar)
    end
  end

  describe "the put_meta/3 function" do
    test "can be used to add metadata to an existing slot" do
      slots = %{47 => {:u, 32, %{foo: :bar}}}

      assert %{slots: ^slots} =
               %Function{name: ~l"foo.bar"}
               |> Block.new([])
               |> Block.put_type(47, {:u, 32, %{}})
               |> Block.put_meta(47, foo: :bar)
    end
  end

  describe "the put_await/3 function" do
    test "can be used to add an await to a block" do
      ref = make_ref()
      awaits = %{47 => ref}

      assert %{awaits: ^awaits} =
               %Function{name: ~l"foo.bar"}
               |> Block.new([])
               |> Block.put_await(47, ref)
    end
  end

  describe "the put_reqs/3 function" do
    test "puts a requirement" do
      %{reqs: [%{foo: :bar}]} =
        %Function{name: ~l"foo.bar"}
        |> Block.new([~l"u8"])
        |> Block.put_reqs(0, foo: :bar)
    end
  end

  describe "the fetch_up! function" do
    test "can be used to retrieve a stored type/meta tuple" do
      block =
        %Function{name: ~l"foo.bar"}
        |> Block.new([])
        |> Block.put_type(47, {:u, 32, %{foo: :bar}})

      assert {{:u, 32, %{foo: :bar}}, %Block{}} = Block.fetch_up!(block, 47)
    end

    test "can be used to retrieve awaited information, which can arbitrarily alter the block" do
      future = make_ref()

      block =
        %Function{name: ~l"foo.bar"}
        |> Block.new([])
        |> Block.put_await(47, future)

      send(self(), {future, {:ok, {:u, 32, %{}}, &Block.put_type(&1, 48, {:u, 64, %{}})}})

      assert {{:u, 32, _}, %{slots: %{48 => {:u, 64, _}}}} = Block.fetch_up!(block, 47)
    end

    test "can be sent an error" do
      future = make_ref()

      block =
        %Function{name: ~l"foo.bar"}
        |> Block.new([])
        |> Block.put_await(47, future)

      send(self(), {future, {:error, %RuntimeError{message: "foobar"}}})

      assert_raise RuntimeError, "foobar", fn ->
        Block.fetch_up!(block, 47)
      end
    end
  end

  describe "call_meta_adder/1" do
    test "creates a lambda that adds metadata to slots" do
      called_block =
        %Function{name: ~l"foo.bar"}
        |> Block.new([:t1, :t2])
        |> Block.put_reqs(0, foo: :bar)
        |> Block.put_reqs(1, baz: :quux)

      caller_block =
        %Function{name: ~l"bar.baz"}
        |> Block.new([])
        |> Block.put_type(47, {:u, 32, %{}})
        |> Block.put_type(48, {:u, 32, %{}})

      lambda = Block.call_meta_adder(called_block)

      assert %Block{
               slots: %{47 => {:u, 32, %{foo: :bar}}, 48 => {:u, 32, %{baz: :quux}}}
             } = lambda.(caller_block, [47, 48])
    end
  end
end
