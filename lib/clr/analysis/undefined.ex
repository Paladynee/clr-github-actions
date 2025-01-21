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

  def analyze(%{loc: {src_slot, _}, src: ~l"undefined"}, _dst_slot, block, _config) do
    {:halt, {:void, Block.put_meta(block, src_slot, undefined: true)}}
  end
end

defimpl Clr.Analysis.Undefined, for: Clr.Air.Instruction.Mem.Load do
  alias Clr.Block
  import Clr.Air.Lvalue
  require Clr.Type

  def analyze(%{src: {src_slot, _}}, _dst_slot, block, _config) do
    case Block.fetch_up!(block, src_slot) do
      {type, block} when Clr.Type.has_refinement(type, :undefined) ->
        raise "undefined usage"
      {type, block} ->
        {:cont, {type, block}}
    end
  end
end
