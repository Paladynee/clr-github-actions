defmodule Clr.Air.Parser do
  require Pegasus
  require Clr.Air

  alias Clr.Air.Function

  # import the following "base" parsers
  Clr.Air.import(Clr.Air.Base, ~w[lineref clobbers name space lbrace rbrace newline]a)
  Clr.Air.import(Clr.Air.Instruction, [:instruction])

  Pegasus.parser_from_string(
    """
    # initialization
    init <- ''
    air <- init function *

    function <- newline? function_head function_meta* code function_foot
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
    codeblock <- lbrace newline codeline+ space* rbrace
    codeblock_clobbers <- lbrace newline (space* clobbers newline)? codeline+ space* rbrace
    codeline <- space* (lineref '=' space instruction) newline
    """,
    air: [parser: true],
    init: [post_traverse: :init],
    function: [post_traverse: :function],
    function_head: [post_traverse: :function_head],
    function_meta: [ignore: true],
    function_foot: [post_traverse: :function_foot],
    codeblock: [export: true, post_traverse: :codeblock],
    codeblock_clobbers: [export: true, post_traverse: :codeblock],
    codeline: [export: true, post_traverse: :codeline]
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
    {rest, [], %{context | code: Map.new(args)}}
  end

  defp codeline(rest, [instruction, "=", lineref], context, _line, _bytes) do
    {rest, [{lineref, instruction}], context}
  end

  defp codeblock(rest, args, context, _line, _bytes), do: {rest, [Map.new(args)], context}

  def parse(string) do
    case air(string) do
      {:ok, [], "", parser, _, _} -> parser
    end
  end
end
