defmodule ClrTest.Analysis.AllocatorTest do
  use ExUnit.Case, async: true

  alias Clr.Analysis.Allocator
  alias Clr.Analysis.Allocator.UseAfterFree
  alias Clr.Analysis.Allocator.DoubleFree
  alias Clr.Air.Function
  alias Clr.Air.Instruction.Function.Call
  alias Clr.Block

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Map.put(:loc, {47, 47})

    {:ok, config: %Allocator{}, block: block}
  end

  @allocator {:fn, [~l"mem.Allocator"],
              {:errorable, ["OutOfMemory"], {:ptr, :one, {:lvalue, ["u8"]}, []}}, []}
  @create_literal {:literal, @allocator, {:function, "create__anon_2535"}}
  @delete_literal {:literal, @allocator, {:function, "destroy__anon_2535"}}
  @c_allocator_literal {:literal, ~l"mem.Allocator",
                        %{
                          "ptr" => :undefined,
                          "vtable" => {:lvalue, ["heap", "c_allocator_vtable"]}
                        }}

  describe "when you do an allocation" do
    # setup block to have the expected type already inside of it.
    setup %{block: block} do
      block =
        Block.put_type(
          block,
          0,
          {:errorable, [~l"FooError"], {:ptr, :one, {:u, 8, %{}}, %{}}, %{}}
        )

      {:ok, block: block}
    end

    test "it marks with correct metadata", %{config: config, block: block} do
      assert {:halt, block} =
               Allocator.analyze(
                 %Call{fn: @create_literal, args: [@c_allocator_literal]},
                 0,
                 block,
                 config
               )

      assert {:errorable, _,
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
    test "it marks as deleted in the basic case", %{config: config, block: block} do
      block =
        Block.put_type(
          block,
          47,
          {:ptr, :one, ~l"u8",
           %{heap: %{function: ~l"foo.bar", loc: {42, 42}, vtable: ~l"heap.c_allocator_vtable"}}}
        )

      assert {{:void, %{}}, block} =
               Allocator.analyze(
                 %Call{fn: @delete_literal, args: [@c_allocator_literal, {47, :keep}]},
                 0,
                 {%{}, block},
                 config
               )

      assert %{deleted: %{function: ~l"foo.bar", loc: {47, 47}}} = Block.get_meta(block, 47)
    end
  end
end
