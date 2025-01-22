defmodule Clr.Analysis do
  # behaviour for an "Analysis" protocol

  alias Clr.Air.Instruction
  alias Clr.Block
  alias Clr.Type

  @type t :: struct()

  # The `analyze` function is designed to be called within an Enum.reduce_while.
  # note that the reduction will always be passed metadata + block, but on termination
  # it is responsible for returning a full type + block tuple, and is responsible
  # for integrating all previous metdata accumulated by continuation calls.
  @callback analyze(Instruction.t(), Type.slot(), {Type.meta(), Block.t()}, t) ::
              {:cont, {Type.meta(), Block.t()}} | {:halt, {Type.t(), Block.t()}}

  @callback always() :: [module]
  @callback when_kept() :: [module]
end
