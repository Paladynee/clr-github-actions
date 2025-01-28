use Protoss

alias Clr.Air.Instruction.Function.Call
alias Clr.Air.Instruction.Maths.Binary

defprotocol Clr.Analysis.Unit do
  @behaviour Clr.Analysis

  @impl true
  def analyze(instruction, slot, meta, config)
after
  defstruct []

  @impl true
  def always, do: [Call]

  @impl true
  def when_kept, do: [Binary]

  defmodule Mismatched do
    defexception [:lhs, :rhs, :function, :loc]

    alias Clr.Zig.Parser

    def message(error) do
      use_point = Parser.format_location(error.function, error.loc)

      """
      Mismatched units found in #{use_point}.
      Left hand side: #{as_string(error.lhs)}
      Right hand side: #{as_string(error.rhs)}
      """
    end

    def as_string(error) do
      error
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.reverse()
      |> Enum.map(fn
        {unit, count} when count > 0 ->
          List.duplicate(["*", unit], count)

        {unit, count} ->
          List.duplicate(["/", unit], -count)
      end)
      |> IO.iodata_to_binary()
      |> String.trim_leading("*")
    end
  end
end

defimpl Clr.Analysis.Unit, for: Call do
  alias Clr.Air
  alias Clr.Block

  @impl true
  def analyze(
        %{fn: {:literal, _type, {:function, "set_units" <> _ = function_name}}},
        slot,
        block,
        _config
      ) do
    units =
      block.function
      |> Call.merge_name(function_name)
      |> Air.get()
      |> process_unit_name

    {:halt, Block.put_meta(block, slot, unit: units)}
  end

  def analyze(_, _, block, _config), do: {:cont, block}

  # this takes advantage of the unique structure of the "set_units" function name.
  defp process_unit_name(%{code: code}) do
    Enum.find_value(code, fn
      {_, %Clr.Air.Instruction.Mem.Store{src: {:literal, _, {:substring, substring, _}}}} ->
        parse_substring(substring)

      _ ->
        nil
    end)
  end

  # format should be "unit * unit / div_unit / div_unit"
  defp parse_substring(substring) do
    [base | divs] = String.split(substring, "/")
    units = String.split(base, "*")

    %{}
    |> group_by(1, units)
    |> group_by(-1, divs)
  end

  defp group_by(so_far, _mode, []), do: so_far

  defp group_by(so_far, mode, [unit | rest]) do
    so_far
    |> Map.update(unit, mode, &(&1 + mode))
    |> group_by(mode, rest)
  end
end

defimpl Clr.Analysis.Unit, for: Binary do
  alias Clr.Air
  alias Clr.Block
  alias Clr.Type

  @impl true
  # note that this function is woefully underimplmented.
  def analyze(%{lhs: {lhs, _}, rhs: {rhs, _}, op: :mul}, slot, block, _config)
      when is_integer(lhs) and is_integer(rhs) do
    lhs_unit = get_unit(lhs, block)
    rhs_unit = get_unit(rhs, block)

    {:cont, Block.put_meta(block, slot, unit: mul_units(lhs_unit, rhs_unit))}
  end

  def analyze(%{lhs: {lhs, _}, rhs: {rhs, _}, op: :add}, slot, block, _config)
      when is_integer(lhs) and is_integer(rhs) do
    lhs_unit = get_unit(lhs, block)
    rhs_unit = get_unit(rhs, block)

    if lhs_unit == rhs_unit do
      {:cont, Block.put_meta(block, slot, unit: lhs_unit)}
    else
      raise Clr.Analysis.Unit.Mismatched,
        lhs: lhs_unit,
        rhs: rhs_unit,
        function: block.function,
        loc: block.loc
    end
  end

  defp get_unit(slot, block) do
    block
    |> Block.fetch!(slot)
    |> Type.get_meta()
    |> Map.get(:unit, %{})
  end

  defp mul_units(lhs_unit, rhs_unit) do
    Enum.reduce(rhs_unit, lhs_unit, fn {unit, count}, so_far ->
      case so_far do
        %{^unit => so_far_count} when so_far_count == -count -> Map.delete(so_far, unit)
        %{^unit => so_far_count} -> Map.put(so_far, unit, so_far_count + count)
        _ -> Map.put(so_far, unit, count)
      end
    end)
  end
end
