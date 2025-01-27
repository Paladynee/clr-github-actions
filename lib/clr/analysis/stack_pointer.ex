use Protoss

defprotocol Clr.Analysis.StackPointer do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, block, config)
after
  defmodule Escape do
    defexception [
      :function,
      :src_loc,
      :esc_loc
    ]

    alias Clr.Zig.Parser

    def message(error) do
      create = Parser.format_location(error.function, error.src_loc)
      escape = Parser.format_location(error.function, error.esc_loc)

      """
      Escape of stack pointer in #{escape}. 
      Value was created in #{create}
      """
    end
  end

  defstruct []

  alias Clr.Air.Instruction.Mem.Alloc
  alias Clr.Air.Instruction.Mem.Store
  alias Clr.Air.Instruction.Function.Ret

  @impl true
  def always, do: [Alloc, Store, Ret]

  @impl true
  def when_kept, do: []
end

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Mem.Alloc do
  alias Clr.Block

  @impl true
  def analyze(_, slot, block, _config) do
    {:cont, Block.put_meta(block, slot, stack: %{loc: block.loc, function: block.function})}
  end
end

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Mem.Store do
  alias Clr.Block

  @impl true
  def analyze(%{dst: {loc, _}, src: {src, _}}, _slot, block, _config)
      when src < length(block.args) do
    # TODO: save parameter names.

    {:cont, Block.put_meta(block, loc, stack: %{loc: {:arg, src}, function: block.function})}
  end

  def analyze(_, _slot, block, _config), do: {:cont, block}
end

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Function.Ret do
  alias Clr.Analysis.StackPointer.Escape
  alias Clr.Block
  alias Clr.Type

  @impl true
  def analyze(%{src: {slot, _}}, _slot, %{function: function} = block, _) when is_integer(slot) do
    block
    |> Block.fetch!(slot)
    |> Type.get_meta()
    |> case do
      %{stack: %{function: ^function, loc: src_loc}} ->
        raise Escape,
          function: function,
          src_loc: src_loc,
          esc_loc: block.loc

      _ ->
        {:cont, block}
    end
  end

  def analyze(_, _slot, block, _config), do: {:cont, block}
end
