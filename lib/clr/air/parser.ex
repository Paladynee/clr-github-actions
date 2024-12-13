defmodule Clr.Air.Parser do
  require Pegasus
  require Clr.Air

  alias Clr.Air.Function
  alias Clr.Air.Instruction

  # import the following "base" parsers
  Clr.Air.import(
    Clr.Air.Base,
    ~w[name space newline]a
  )

  # import the "instruction" parser
  Clr.Air.import(
    Clr.Air.Instruction,
    ~w[codeline]a
  )

  Pegasus.parser_from_string(
    """
    # initialization
    init <- ''
    air <- init function *

    function <- function_head function_meta* code function_foot
    function_head <- '# Begin Function AIR:' space name ':' newline
    function_foot <- '# End Function AIR:' space name newline?
    function_meta <- function_meta_title space+ function_meta_info newline
    function_meta_title <- '# Total AIR+Liveness bytes:' / 
      '# AIR Instructions:' / 
      '# AIR Extra Data:' / 
      '# Liveness tomb_bits:' / 
      '# Liveness Extra Data:' / 
      '# Liveness special table:'
    function_meta_info <- [^\n]+

    code <- codeline+
    """,
    air: [parser: true],
    init: [post_traverse: :init],
    function: [post_traverse: :function],
    function_head: [post_traverse: :function_head],
    function_meta: [ignore: true],
    function_foot: [post_traverse: :function_foot],
  )

  defp init(rest, _, _context, _line, _bytes) do
    {rest, [], %Function{}}
  end

  defp function_head(rest, [_, name, _], context, _line, _bytes) do
    {rest, [], %{context | name: name}}
  end

  defp function_foot(rest, [name, _], %{name: expected_name} = context, _line, _bytes) do
    if expected_name != name do
      raise "function foot name #{name} mismatches expected name #{expected_name}"
    end

    {rest, [], context}
  end

  defp function(rest, args, context, _line, _bytes) do
    {rest, [], %{context | code: Instruction.to_code(args)}}
  end

  def parse(string) do
    case air(string) do
      {:ok, [], "", parser, _, _} -> parser
    end
  end
end
