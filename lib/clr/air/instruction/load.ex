defmodule Clr.Air.Instruction.Load do
  # takes a value from a pointer and puts into a vm slot.

  defstruct [:type, :loc]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[slotref cs lparen rparen type literal]a)

  Pegasus.parser_from_string(
    "load <- 'load' lparen type cs (slotref / literal) rparen",
    load: [export: true, post_traverse: :load]
  )

  def load(rest, [loc, type, "load"], context, _slot, _bytes) do
    {rest, [%__MODULE__{type: type, loc: loc}], context}
  end

  use Clr.Air.Instruction
  alias Clr.Analysis

  def analyze(%{type: type, loc: {src_slot, _}}, slot, analysis) do
    case Analysis.fetch!(analysis, src_slot) do
      {:ptr, _, _, opts} ->
        cond do
          opts[:undefined] ->
            raise Clr.UndefinedUsage,
              function: Clr.Air.Lvalue.as_string(analysis.name),
              row: analysis.row,
              col: analysis.col

          opts[:heap] == :deleted ->
            raise Clr.UseAfterFreeError,
              function: Clr.Air.Lvalue.as_string(analysis.name),
              row: analysis.row,
              col: analysis.col
          :else ->
            Analysis.put_type(analysis, slot, type)
        end
    end

  end
end
