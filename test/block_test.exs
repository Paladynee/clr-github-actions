defmodule ClrTest.BlockTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Function
  alias Clr.Block
  alias Clr.Type

  import Clr.Air.Lvalue

  describe "for the put_type/3,4 function" do
    test "we can put a basic type and no metadata are added" do
      slots = %{47 => {:u, 32, %{}}}

      assert %{slots: ^slots} =
               %Function{name: ~l"foo.bar"}
               |> Block.new([], :void)
               |> Block.put_type(47, {:u, 32, %{}})
    end

    test "metadata can be added too" do
      slots = %{47 => {:u, 32, %{foo: :bar}}}

      assert %{slots: ^slots} =
               %Function{name: ~l"foo.bar"}
               |> Block.new([], :void)
               |> Block.put_type(47, {:u, 32, %{}}, foo: :bar)
    end
  end

  describe "the put_meta/3 function" do
    test "can be used to add metadata to an existing slot" do
      slots = %{47 => {:u, 32, %{foo: :bar}}}

      assert %{slots: ^slots} =
               %Function{name: ~l"foo.bar"}
               |> Block.new([], :void)
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
               |> Block.new([], :void)
               |> Block.put_await(47, ref)
    end
  end

  describe "the fetch_up! function" do
    test "can be used to retrieve a stored type/meta tuple" do
      block =
        %Function{name: ~l"foo.bar"}
        |> Block.new([], :void)
        |> Block.put_type(47, {:u, 32, %{foo: :bar}})

      assert {{:u, 32, %{foo: :bar}}, %Block{}} = Block.fetch_up!(block, 47)
    end

    test "can be used to retrieve awaited information, which can arbitrarily alter the block" do
      future = make_ref()

      block =
        %Function{name: ~l"foo.bar"}
        |> Block.new([], :void)
        |> Block.put_await(47, future)

      send(self(), {future, {:ok, {:u, 32, %{}}, &Block.put_type(&1, 48, {:u, 64, %{}})}})

      assert {{:u, 32, _}, %{slots: %{48 => {:u, 64, _}}}} = Block.fetch_up!(block, 47)
    end

    test "can be sent an error" do
      future = make_ref()

      block =
        %Function{name: ~l"foo.bar"}
        |> Block.new([], :void)
        |> Block.put_await(47, future)

      send(self(), {future, {:error, %RuntimeError{message: "foobar"}}})

      assert_raise RuntimeError, "foobar", fn ->
        Block.fetch_up!(block, 47)
      end
    end
  end

  describe "make_call_resolver/1" do
    test "creates a lambda that adds metadata to slots" do
      called_block =
        Block.new(
          %Function{name: ~l"foo.bar"},
          [{:u, 32, %{foo: :bar}}, {:u, 32, %{baz: :quux}}],
          :void
        )

      caller_block =
        %Function{name: ~l"bar.baz"}
        |> Block.new([], :void)
        |> Block.put_type(47, {:u, 32, %{}})
        |> Block.put_type(48, {:u, 32, %{}})

      lambda = Block.make_call_resolver(called_block)

      assert %Block{
               slots: %{47 => {:u, 32, %{foo: :bar}}, 48 => {:u, 32, %{baz: :quux}}}
             } = lambda.(caller_block, [47, 48])
    end
  end

  describe "update_type" do
    setup do
      {:ok, block: Block.new(%Function{name: ~l"foo.bar"}, [], :void)}
    end

    test "will update a type in a block", %{block: block} do
      assert {:u, 32, %{foo: :bar}} =
               block
               |> Block.put_type(47, {:u, 32, %{}})
               |> Block.update_type!(47, &Type.put_meta(&1, foo: :bar))
               |> Block.fetch!(47)
    end

    test "will walk a pointer when there's a pointer reference in there", %{block: block} do
      assert {:ptr, :one, {:u, 32, %{foo: :bar}}, %{}} =
               block
               |> Block.put_type(47, {:ptr, :one, {:u, 32, %{}}, %{}})
               |> Block.put_type(48, {:u, 32, %{}})
               |> Block.put_ref(48, 47)
               |> Block.update_type!(48, &Type.put_meta(&1, foo: :bar))
               |> Block.fetch!(47)
    end

    test "will walk twice, if that's a thing", %{block: block} do
      assert {:ptr, :one, {:ptr, :one, {:u, 32, %{foo: :bar}}, %{}}, %{}} =
               block
               |> Block.put_type(47, {:ptr, :one, {:ptr, :one, {:u, 32, %{}}, %{}}, %{}})
               |> Block.put_type(48, {:ptr, :one, {:u, 32, %{}}, %{}})
               |> Block.put_ref(48, 47)
               |> Block.put_type(49, {:u, 32, %{}})
               |> Block.put_ref(49, 48)
               |> Block.update_type!(49, &Type.put_meta(&1, foo: :bar))
               |> Block.fetch!(47)
    end
  end

  @tag :skip
  test "get and set priv data"
end
