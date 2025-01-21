use Protoss

defprotocol Clr.Analysis.Undefined do
  @behaviour Clr.Analysis

  def analyze(instruction, slot, block, config)

after
  defstruct []
end

defimpl Clr.Analysis.Undefined, for: Clr.Air.Instruction.Mem.Store do

  alias Clr.Block
  import Clr.Air.Lvalue

  def analyze(%{loc: {src, _}, src: ~l"undefined"}, slot, block, config) do
    {:halt, {:void, Block.put_meta(block, src, undefined: true)}}
  end
end