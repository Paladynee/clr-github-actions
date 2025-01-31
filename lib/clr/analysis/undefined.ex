use Protoss

defprotocol Clr.Analysis.Undefined do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, meta, config)
after
  defstruct []

  alias Clr.Air.Instruction.Mem.Load
  alias Clr.Air.Instruction.Mem.Store

  def meta(block), do: Map.take(block, ~w[loc function]a)

  @impl true
  def always, do: [Load, Store]

  @impl true
  def when_kept, do: []

  @impl true
  def on_call_requirement(_block, type), do: type
end

defmodule Clr.Analysis.Undefined.Use do
  defexception [
    :src_function,
    :src_loc,
    :use_function,
    :use_loc
  ]

  alias Clr.Zig.Parser

  def message(error) do
    use_point = Parser.format_location(error.use_function, error.use_loc)
    src_point = Parser.format_location(error.src_function, error.src_loc)

    """
    Use of undefined value in #{use_point}.
    Value was set undefined in #{src_point}
    """
  end
end

defimpl Clr.Analysis.Undefined, for: Clr.Air.Instruction.Mem.Store do
  alias Clr.Analysis.Undefined
  alias Clr.Block
  alias Clr.Type

  def analyze(%{dst: {slot, _}, src: {:literal, _, :undefined}}, _dst_slot, block, _config)
      when is_integer(slot) do
    {:ptr, :one, child, ptr_meta} = Block.fetch!(block, slot)

    new_type = {:ptr, :one, Type.put_meta(child, undefined: Undefined.meta(block)), ptr_meta}

    {:cont, Block.put_type(block, slot, new_type)}
  end

  def analyze(%{dst: {src_slot, _}, src: {:literal, _, _other}}, _dst_slot, block, _config) do
    {:ptr, :one, child, ptr_meta} = Block.fetch!(block, src_slot)

    new_type = {:ptr, :one, Type.delete_meta(child, :undefined), ptr_meta}

    {:cont, Block.put_type(block, src_slot, new_type)}
  end

  def analyze(_command, _dst_slot, block, _config), do: {:cont, block}
end

defimpl Clr.Analysis.Undefined, for: Clr.Air.Instruction.Mem.Load do
  alias Clr.Type
  alias Clr.Analysis.Undefined.Use
  alias Clr.Block
  alias Clr.Zig.Parser

  require Type

  def analyze(_, slot, block, _config) do
    case Block.fetch!(block, slot) do
      type when Type.has_refinement(type, :undefined) ->
        src = Type.get_meta(type).undefined

        raise Use,
          src_function: src.function,
          src_loc: src.loc,
          use_function: block.function,
          use_loc: block.loc

      _ ->
        {:cont, block}
    end
  end
end
