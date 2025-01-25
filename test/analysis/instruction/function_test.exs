defmodule ClrTest.Analysis.Instruction.FunctionTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Instruction
  alias Clr.Air.Function
  alias Clr.Block

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([])
      |> Map.put(:loc, {47, 47})

    {:ok, block: block, config: %Instruction{}}
  end

  describe "arg" do
    alias Clr.Air.Instruction.Function.Arg

    test "returns the type of the arg statement", %{block: block} do
      block = %{block | args: [{:u, 8, %{foo: :bar}}], reqs: [%{}]}

      assert {{:ptr, :one, {:u, 8, %{foo: :bar}}, %{}}, _} =
               Instruction.slot_type(%Arg{type: {:ptr, :one, ~l"u8", []}}, 0, block)
    end
  end

  describe "call" do
    alias Clr.Air.Instruction.Function.Call

    test "returns the type of the call statement", %{block: block} do
      assert {{:u, 8, %{}}, _} =
               Instruction.slot_type(
                 %Call{
                   fn: {:literal, {:fn, [], ~l"u8", []}, {:function, "initStatic"}},
                   args: []
                 },
                 0,
                 block
               )
    end
  end

  describe "ret" do
    alias Clr.Air.Instruction.Function.Ret

    test "returns the type of the ret statement", %{block: block} do
      assert {:noreturn, _} = Instruction.slot_type(%Ret{}, 0, block)
    end
  end

  describe "ret_ptr" do
    alias Clr.Air.Instruction.Function.RetPtr

    test "returns the type of the ret_ptr statement", %{block: block} do
      assert {{:ptr, :one, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(%RetPtr{type: {:ptr, :one, ~l"u8", []}}, 0, block)
    end
  end

  describe "ret_addr" do
    alias Clr.Air.Instruction.Function.RetAddr

    test "returns the type of the ret_addr statement", %{block: block} do
      block = %{block | args: [{:u, 8, %{}}], return: {:u, 8, %{}}}

      assert {{:ptr, :one, {:fn, [{:u, 8, %{}}], {:u, 8, %{}}, %{}}, %{}}, _} =
               Instruction.slot_type(%RetAddr{}, 0, block)
    end
  end
end
