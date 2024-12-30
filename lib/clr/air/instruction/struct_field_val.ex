defmodule Clr.Air.Instruction.StructFieldVal do
  defstruct [:src, :index]

  require Pegasus
  require Clr.Air

  Clr.Air.import(~w[lineref int cs lparen rparen]a)

  Pegasus.parser_from_string(
    "struct_field_val <- 'struct_field_val' lparen lineref cs int rparen",
    struct_field_val: [export: true, post_traverse: :struct_field_val]
  )

  def struct_field_val(rest, [index, src, "struct_field_val"], context, _line, _bytes) do
    {rest, [%__MODULE__{src: src, index: index}], context}
  end

  use Clr.Air.Instruction

  alias Clr.Analysis

  def analyze(%{src: {src_line, _keep_or_clobber}, index: index}, dst_line, analysis) do
    {:struct, struct_types} = Map.fetch!(analysis.types, src_line)
    line_type = Enum.at(struct_types, index) || raise "Invalid struct field access"
    Analysis.put_type(analysis, dst_line, line_type)
  end
end
