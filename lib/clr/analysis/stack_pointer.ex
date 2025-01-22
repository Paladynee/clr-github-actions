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

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Mem.Alloc do
  alias Clr.Air.Instruction.Mem.Alloc
  alias Clr.Air.Lvalue

  @impl true
  def analyze(%Alloc{}, _slot, {meta, block}, _config) do
    meta = Map.put(meta, :stack, %{loc: block.loc, function: Lvalue.as_string(block.function)})

    {:cont, {meta, block}}
  end
end

defimpl Clr.Analysis.StackPointer, for: Clr.Air.Instruction.Mem.Store do
  alias Clr.Air.Instruction.Mem.Store
  alias Clr.Air.Lvalue
  alias Clr.Block

  @impl true
  def analyze(%Store{loc: {loc, _}, src: {src, _}}, _slot, {store_meta, block}, _config)
      when src < length(block.args_meta) do
    stack_meta =
      %{loc: {:arg, src}, function: Lvalue.as_string(block.function), name: "param"}

    new_block = Block.put_meta(block, loc, stack: stack_meta)

    {:cont, {store_meta, new_block}}
  end

  def analyze(_, _slot, meta_block, _config), do: {:cont, meta_block}
end
