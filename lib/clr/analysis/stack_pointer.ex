use Protoss

defprotocol Clr.Analysis.StackPointer do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, block, config)
after
  defstruct []

  alias Clr.Air.Instruction.Mem.Alloc
  alias Clr.Air.Instruction.Mem.Store

  @impl true
  def always, do: [Alloc, Store]

  @impl true
  def when_kept, do: []
end

defmodule Clr.Analysis.StackPointer.Escape do
  defexception [
    :function,
    :src_loc,
    :esc_loc
  ]

  def message(error) do
    "Stack pointer escaped from function #{error.function}, created at #{inspect(error.src_loc)}, returned from #{inspect(error.esc_loc)}"
  end
end

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Mem.Alloc do
  @impl true
  def analyze(_, _slot, {meta, block}, _config) do
    meta = Map.put(meta, :stack, %{loc: block.loc, function: block.function})

    {:cont, {meta, block}}
  end
end

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Mem.Store do
  alias Clr.Block

  @impl true
  def analyze(%{loc: {loc, _}, src: {src, _}}, _slot, {store_meta, block}, _config)
      when src < length(block.args_meta) do
    stack_meta =
      %{loc: {:arg, src}, function: block.function, name: "param"}

    new_block = Block.put_meta(block, loc, stack: stack_meta)

    {:cont, {store_meta, new_block}}
  end

  def analyze(_, _slot, meta_block, _config), do: {:cont, meta_block}
end

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Function.Ret do
  @impl true

  alias Clr.Air.Lvalue
  alias Clr.Analysis.StackPointer.Escape
  alias Clr.Block
  alias Clr.Type

  def analyze(%{src: {slot, _}}, _slot, {meta, %{function: function} = block}, _) do
    {type, block} = Block.fetch_up!(block, slot)

    case Type.get_meta(type) do
      %{stack: %{function: ^function} = stack_info} ->
        raise Escape,
          function: Lvalue.as_string(function),
          src_loc: stack_info.loc,
          esc_loc: block.loc

      _ ->
        {:cont, {meta, block}}
    end
  end
end
