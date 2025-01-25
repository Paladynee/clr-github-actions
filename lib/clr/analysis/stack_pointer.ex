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

    def message(error) do
      "Stack pointer escaped from function #{error.function}, created at #{inspect(error.src_loc)}, returned from #{inspect(error.esc_loc)}"
    end
  end

  defstruct []

  alias Clr.Air.Instruction.Mem.Alloc
  alias Clr.Air.Instruction.Mem.Store

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

    {:cont,
     Block.put_meta(block, loc,
       stack: %{loc: {:arg, src}, function: block.function, name: "param"}
     )}
  end

  def analyze(_, _slot, block, _config), do: {:cont, block}
end

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Function.Ret do
  alias Clr.Air.Lvalue
  alias Clr.Analysis.StackPointer.Escape
  alias Clr.Block
  alias Clr.Type

  @impl true
  def analyze(%{src: {slot, _}}, _slot, %{function: function} = block, _) do
    block
    |> Block.fetch!(slot)
    |> Type.get_meta()
    |> case do
      %{stack: %{function: ^function, loc: src_loc}} ->
        raise Escape,
          function: Lvalue.as_string(function),
          src_loc: src_loc,
          esc_loc: block.loc

      _ ->
        {:cont, block}
    end
  end
end
