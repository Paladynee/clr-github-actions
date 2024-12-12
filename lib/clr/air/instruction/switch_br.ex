defmodule Clr.Air.Instruction.SwitchBr do
  @behaviour Clr.Air.Instruction

  alias Clr.Air.Instruction

  defstruct [:test, :cases]

  def initialize([test | rest]) do
    %__MODULE__{test: test, cases: get_cases(rest, [{[], []}], :code)}
  end

  defguard is_literal(tuple) when is_number(elem(tuple, 1))

  defguard is_line(tuple)
           when is_integer(elem(elem(tuple, 0), 0)) and
                  elem(elem(tuple, 0), 1) in ~w[clobber keep]a

  def get_cases([literal | rest], [{head_cases, head_code} | other_branches], :cases)
      when is_literal(literal) do
    get_cases(rest, [{[literal | head_cases], head_code} | other_branches], :cases)
  end

  def get_cases([literal | rest], other_branches, :code) when is_literal(literal) do
    get_cases(rest, [{[literal], []} | other_branches], :cases)
  end

  def get_cases(["else" | rest], other_branches, :code) do
    get_cases(rest, [{:else, []} | other_branches], :cases)
  end

  def get_cases([line | rest], [{head_cases, []} | other_branches], :cases) when is_line(line) do
    get_cases(rest, [{head_cases, [line]} | other_branches], :code)
  end

  def get_cases([line | rest], [{head_cases, head_code} | other_branches], :code)
      when is_line(line) do
    get_cases(rest, [{head_cases, [line | head_code]} | other_branches], :code)
  end

  def get_cases([], all_branches, :code) do
    Enum.map(all_branches, fn {cases, code} -> {cases, Instruction.to_code(code)} end)
  end
end
