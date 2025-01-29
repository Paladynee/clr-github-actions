defmodule ClrTest.Analysis.Instruction.DbgTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Instruction
  alias Clr.Air.Function
  alias Clr.Block

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([], :void)
      |> Map.put(:loc, {47, 47})

    {:ok, block: block, config: %Instruction{}}
  end

  describe "dbg_stmt" do
    alias Clr.Air.Instruction.Dbg.Stmt

    test "returns void as the slot type", %{block: block} do
      assert {:void, _} = Instruction.slot_type(%Stmt{}, 0, block)
    end
  end

  describe "dbg_emtpy_stmt" do
    alias Clr.Air.Instruction.Dbg.EmptyStmt

    test "returns void as the slot type", %{block: block} do
      assert {:void, _} = Instruction.slot_type(%EmptyStmt{}, 0, block)
    end
  end

  describe "dbg_inline_block" do
    @tag :skip
    test "runs the block"
  end

  describe "dbg_var_ptr" do
    alias Clr.Air.Instruction.Dbg.VarPtr

    test "returns void as the slot type", %{block: block} do
      assert {:void, _} = Instruction.slot_type(%VarPtr{}, 0, block)
    end
  end

  describe "dbg_var_val" do
    alias Clr.Air.Instruction.Dbg.VarVal

    test "returns void as the slot type", %{block: block} do
      assert {:void, _} = Instruction.slot_type(%VarVal{}, 0, block)
    end
  end

  describe "dbg_arg_inline" do
    alias Clr.Air.Instruction.Dbg.ArgInline

    test "returns void as the slot type", %{block: block} do
      assert {:void, _} = Instruction.slot_type(%ArgInline{}, 0, block)
    end
  end
end
