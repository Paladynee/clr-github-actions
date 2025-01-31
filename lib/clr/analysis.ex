defmodule Clr.Analysis do
  # behaviour for an "Analysis" protocol

  alias Clr.Air.Instruction
  alias Clr.Block
  alias Clr.Type

  @type t :: struct()

  # The `analyze` function is designed to be called within an Enum.reduce_while.
  # prior to being called, the slot location should have an initial type set in there
  # and if any changes are to be made, the `analyze` function should alter them
  # in there.
  @callback analyze(Instruction.t(), Type.slot(), Block.t(), t) :: {:cont | :halt, Block.t()}

  # transforms or augments annotations when a call comes back.
  @callback on_call_requirement(Block.t, Type.t, Clr.loc) :: Type.t
  @callback always() :: [module]
  @callback when_kept() :: [module]
end
