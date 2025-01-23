defmodule ClrTest.Analysis.StackPointerTest do
  use ExUnit.Case, async: true

  alias Clr.Analysis.StackPointer
  alias Clr.Analysis.StackPointer.Escape
  alias Clr.Air.Function
  alias Clr.Block

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Map.put(:loc, {47, 47})

    {:ok, config: %StackPointer{}, block: block}
  end

  alias Clr.Air.Instruction.Mem.Alloc

  test "when you do a stack allocation", %{config: config, block: block} do
    assert {:cont, {%{stack: %{function: ~l"foo.bar", loc: {47, 47}}}, _}} =
             StackPointer.analyze(%Alloc{type: ~l"u8"}, 0, {%{}, block}, config)
  end

  alias Clr.Air.Instruction.Mem.Store

  test "when you store something that is an argument", %{config: config, block: block} do
    block = %{block | args_meta: [%{}], reqs: [%{}], slots: %{2 => {:u, 8, %{}}}}

    assert {:cont, {_, updated_block}} =
             StackPointer.analyze(
               %Store{loc: {2, :keep}, src: {0, :keep}},
               3,
               {%{}, block},
               config
             )

    assert %{stack: %{function: ~l"foo.bar", loc: {:arg, 0}}} = Block.get_meta(updated_block, 2)
  end

  alias Clr.Air.Instruction.Function.Ret

  test "when you return a stack pointer", %{config: config, block: block} do
    block = %{
      block
      | slots: %{
          0 => {:ptr, :one, {:u, 8, %{}}, %{stack: %{function: ~l"foo.bar", loc: {48, 48}}}}
        }
    }

    assert_raise Escape, fn ->
      StackPointer.analyze(%Ret{src: {0, :clobber}}, 42, {%{}, block}, config)
    end
  end
end
