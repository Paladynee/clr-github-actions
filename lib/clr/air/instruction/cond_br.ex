defmodule Clr.Air.Instruction.CondBr do
  @behaviour Clr.Air.Instruction

  alias Clr.Air.Instruction

  defstruct [:cond, :true_branch, :false_branch, :unused]

  def initialize(args) do
    [false_block, true_block, condition] = split(args, [[]])

    true_code = Instruction.to_code(true_block)
    false_code = Instruction.to_code(false_block)

    %__MODULE__{cond: condition, true_branch: true_code, false_branch: false_code}
  end

  def split([], so_far), do: so_far

  def split(["poi" | rest], so_far) do
    split(rest, [[] | so_far])
  end

  def split([head | rest], [head_so_far | rest_so_far]) do
    split(rest, [[head | head_so_far] | rest_so_far])
  end
end
