defmodule ClrTest.Analysis.AllocatorTest do
  use ExUnit.Case, async: true

  alias Clr.Analysis.Allocator
  alias Clr.Analysis.Allocator.Mismatch
  alias Clr.Analysis.Allocator.UseAfterFree
  alias Clr.Analysis.Allocator.DoubleFree
  alias Clr.Analysis.Allocator.CallDeleted
  alias Clr.Air.Function
  alias Clr.Air.Instruction.Function.Call
  alias Clr.Block

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([], :void)
      |> Map.put(:loc, {47, 47})

    {:ok, config: %Allocator{}, block: block}
  end

  @allocator {:fn, [~l"mem.Allocator"],
              {:errorunion, ["OutOfMemory"], {:ptr, :one, {:lvalue, ["u8"]}, []}}, []}
  @create_literal {:literal, @allocator, {:function, "create__anon_2535"}}
  @delete_literal {:literal, @allocator, {:function, "destroy__anon_2535"}}
  @c_allocator_literal {:literal, ~l"mem.Allocator",
                        %{
                          "ptr" => :undefined,
                          "vtable" => {:lvalue, ["heap", "c_allocator_vtable"]}
                        }}

  describe "when you do an allocation" do
    test "it marks with correct metadata", %{config: config, block: block} do
      # setup block to have the expected type already inside of it
      block =
        Block.put_type(
          block,
          0,
          {:errorunion, [~l"FooError"], {:ptr, :one, {:u, 8, %{}}, %{}}, %{}}
        )

      assert {:halt, block} =
               Allocator.analyze(
                 %Call{fn: @create_literal, args: [@c_allocator_literal]},
                 0,
                 block,
                 config
               )

      assert {:errorunion, _,
              {:ptr, :one, {:u, 8, %{undefined: %{function: ~l"foo.bar", loc: {47, 47}}}},
               %{
                 heap: %{
                   function: ~l"foo.bar",
                   loc: {47, 47},
                   vtable: ~l"heap.c_allocator_vtable"
                 }
               }}, %{}} = Block.fetch!(block, 0)
    end
  end

  describe "when you run a deallocation" do
    setup %{block: block} do
      {:ok, block: Block.put_type(block, 0, :void)}
    end

    test "it marks as deleted in the basic case", %{config: config, block: block} do
      block =
        Block.put_type(
          block,
          47,
          {:ptr, :one, {:u, 8, %{}}, %{}},
          %{heap: %{function: ~l"foo.bar", loc: {42, 42}, vtable: ~l"heap.c_allocator_vtable"}}
        )

      assert {:halt, block} =
               Allocator.analyze(
                 %Call{fn: @delete_literal, args: [@c_allocator_literal, {47, :keep}]},
                 0,
                 block,
                 config
               )

      assert :void = Block.fetch!(block, 0)
      assert %{deleted: %{function: ~l"foo.bar", loc: {47, 47}}} = Block.get_meta(block, 47)
    end

    test "it can chase when the slot is known to have a slot that points to it."

    test "it raises when the allocator doesn't match", %{config: config, block: block} do
      block =
        Block.put_type(
          block,
          47,
          {:ptr, :one, {:u, 8, %{}}, %{}},
          %{
            heap: %{function: ~l"foo.bar", loc: {42, 42}, vtable: ~l"heap.other_allocator_vtable"}
          }
        )

      assert_raise Mismatch, fn ->
        Allocator.analyze(
          %Call{fn: @delete_literal, args: [@c_allocator_literal, {47, :keep}]},
          0,
          block,
          config
        )
      end
    end

    test "it raises when you attempt to free a stack-allocated pointer", %{
      config: config,
      block: block
    } do
      block =
        Block.put_type(
          block,
          47,
          {:ptr, :one, {:u, 8, %{}}, %{}},
          stack: %{function: ~l"bar.baz", loc: {42, 42}}
        )

      assert_raise Mismatch, fn ->
        Allocator.analyze(
          %Call{fn: @delete_literal, args: [@c_allocator_literal, {47, :keep}]},
          0,
          block,
          config
        )
      end
    end

    test "it raises when you do a double free", %{config: config, block: block} do
      block =
        Block.put_type(
          block,
          47,
          {:ptr, :one, {:u, 8, %{}}, %{}},
          heap: %{function: ~l"foo.bar", loc: {42, 42}, vtable: ~l"heap.c_allocator_vtable"},
          deleted: %{function: ~l"foo.bar", loc: {42, 42}}
        )

      assert_raise DoubleFree, fn ->
        Allocator.analyze(
          %Call{fn: @delete_literal, args: [@c_allocator_literal, {47, :keep}]},
          0,
          block,
          config
        )
      end
    end

    test "it raises when you do attempt free a transferred pointer", %{
      config: config,
      block: block
    } do
      block =
        Block.put_type(
          block,
          47,
          {:ptr, :one, {:u, 8, %{}}, %{}},
          heap: %{function: ~l"foo.bar", loc: {42, 42}, vtable: ~l"heap.c_allocator_vtable"},
          transferred: %{function: ~l"bar.baz", loc: {42, 42}}
        )

      assert_raise DoubleFree, fn ->
        Allocator.analyze(
          %Call{fn: @delete_literal, args: [@c_allocator_literal, {47, :keep}]},
          0,
          block,
          config
        )
      end
    end

    test "when you attempt to pass a pointer into a function that has already been deleted", %{
      config: config,
      block: block
    } do
      block =
        Block.put_type(
          block,
          47,
          {:ptr, :one, {:u, 8, %{}}, %{}},
          deleted: %{function: ~l"foo.bar", loc: {42, 42}}
        )

      assert_raise CallDeleted, fn ->
        Allocator.analyze(
          %Call{fn: {:literal, %{}, {:function, "some_function"}}, args: [{47, :keep}]},
          0,
          block,
          config
        )
      end
    end
  end

  describe "when you attempt to use a pointer that has been deleted" do
    alias Clr.Air.Instruction.Mem.Load

    test "it raises on deleted", %{config: config, block: block} do
      block =
        block
        |> Block.put_type(0, {:u, 8, %{}})
        |> Block.put_type(
          47,
          {:ptr, :one, {:u, 8, %{}}, %{}},
          heap: %{function: ~l"foo.bar", loc: {1, 1}, vtable: ~l"heap.c_allocator_vtable"},
          deleted: %{function: ~l"foo.bar", loc: {42, 42}}
        )

      assert_raise UseAfterFree, fn ->
        Allocator.analyze(%Load{type: {:u, 8, %{}}, src: {47, :keep}}, 0, block, config)
      end
    end

    test "it raises on transferred", %{config: config, block: block} do
      block =
        block
        |> Block.put_type(0, {:u, 8, %{}})
        |> Block.put_type(
          47,
          {:ptr, :one, {:u, 8, %{}}, %{}},
          heap: %{function: ~l"foo.bar", loc: {1, 1}, vtable: ~l"heap.c_allocator_vtable"},
          transferred: %{function: ~l"bar.baz", loc: {42, 42}}
        )

      assert_raise UseAfterFree, fn ->
        Allocator.analyze(%Load{type: {:u, 8, %{}}, src: {47, :keep}}, 0, block, config)
      end
    end
  end
end
