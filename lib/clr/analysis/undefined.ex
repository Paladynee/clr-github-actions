use Protoss

defprotocol Clr.Analysis.Undefined do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, meta, config)
after
  defstruct []

  alias Clr.Air.Instruction.Mem.Load
  alias Clr.Air.Instruction.Mem.Store

  @impl true
  def always, do: [Load, Store]

  @impl true
  def when_kept, do: []
end

defmodule Clr.Analysis.Undefined.Use do
  defexception [
    :src_function,
    :src_loc,
    :use_function,
    :use_loc
  ]

  def message(error) do
    use_point = Clr.location_string(error.use_function, error.use_loc)
    src_point = Clr.location_string(error.src_function, error.src_loc)
    "Use of undefined value in function #{use_point} (value set undefined at #{src_point})"
  end
end

defimpl Clr.Analysis.Undefined, for: Clr.Air.Instruction.Mem.Store do
  alias Clr.Air.Lvalue
  alias Clr.Block
  import Lvalue

  def analyze(%{loc: {src_slot, _}, src: ~l"undefined"}, _dst_slot, {meta, block}, _config) do
    {:cont,
     {meta,
      Block.put_meta(block, src_slot,
        undefined: %{loc: block.loc, function: Lvalue.as_string(block.function)}
      )}}
  end

  # TODO: figure out other cases.
end

defimpl Clr.Analysis.Undefined, for: Clr.Air.Instruction.Mem.Load do
  alias Clr.Air.Lvalue
  alias Clr.Type
  alias Clr.Analysis.Undefined.Use
  alias Clr.Block

  require Type

  def analyze(%{src: {src_slot, _}}, _dst_slot, {meta, block}, _config) do
    case Block.fetch_up!(block, src_slot) do
      {type, block} when Type.has_refinement(type, :undefined) ->
        src = Type.get_meta(type).undefined

        raise Use,
          src_function: Lvalue.as_string(src.function),
          src_loc: src.loc,
          use_function: Lvalue.as_string(block.function),
          use_loc: block.loc

      {_, block} ->
        {:cont, {meta, block}}
    end
  end
end
