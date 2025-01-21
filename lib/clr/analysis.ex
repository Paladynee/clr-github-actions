defmodule Clr.Analysis do
  # behaviour for an "Analysis" protocol

  alias Clr.Air.Instruction
  alias Clr.Block
  alias Clr.Type

  @type t :: struct()

  @callback analyze(Instruction.t(), Type.slot(), Block.t(), t) ::
              {:cont, {Type.t(), Block.t()}} | {:halt, {Type.t(), Block.t()}}
end
