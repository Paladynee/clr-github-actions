defmodule Clr.Air.Function do
  require Pegasus
  require Clr.Air

  defstruct [:name, code: %{}]

  @type t :: %__MODULE__{
          name: term,
          # change to codeblock.t
          code: term
        }

  # TODO: move codeblock and codeline stuff into its own module/domain

  # import the following "base" parsers
  Clr.Air.import(~w[lvalue instruction slotref clobbers space lbrace rbrace newline]a)

  Pegasus.parser_from_string(
    """
    # initialization
    init <- ''
    air <- init function *

    function <- newline? function_head function_meta* code function_foot
    function_head <- '# Begin Function AIR:' space lvalue ':' newline
    function_foot <- '# End Function AIR:' space lvalue newline?
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
    codeline <- space* (slotref '=' space instruction) newline
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

  defp init(rest, _, _context, _slot, _bytes) do
    {rest, [], %__MODULE__{}}
  end

  defp function_head(rest, [_, name, _], context, _slot, _bytes) do
    {rest, [], %{context | name: name}}
  end

  defp function_foot(rest, [name, _], %{name: expected_name} = context, _slot, _bytes) do
    if expected_name != name do
      raise "function foot name #{name} mismatches expected name #{expected_name}"
    end

    {rest, [], context}
  end

  defp function(rest, args, context, _slot, _bytes) do
    {rest, [], %{context | code: Map.new(args)}}
  end

  defp codeline(rest, [instruction, "=", slotref], context, _slot, _bytes) do
    {rest, [{slotref, instruction}], context}
  end

  defp codeblock(rest, args, context, _slot, _bytes), do: {rest, [Map.new(args)], context}

  def parse(string) do
    case air(string) do
      {:ok, [], "", function, _, _} ->
        if prefix = Clr.debug_prefix() do
          if match?({:lvalue, [^prefix, _]}, function.name) do
            IO.puts(string)
          end
        end

        function
    end
  end

  def put_slots([function | rest], lines), do: [put_slots(function, lines) | rest]

  def put_slots(function, lines), do: %{function | code: lines}
end
