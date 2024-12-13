defmodule Clr.Air.Base do
  # basic parser and parser combinators for AIR parsing

  require Pegasus

  Pegasus.parser_from_string(
    """
    # line numbers
    lineref <- clobber / keep
    clobbers <- clobber (space clobber)*
    keep <- percent int space?
    clobber <- percent int bang

    int <- [0-9]+

    # strings and names
    squoted <- singleq name singleq
    dquoted <- doubleq name doubleq
    dstring <- doubleq [^"]* doubleq

    name <- [0-9a-zA-Z._@] +

    # this is convenient because it occurs all over the place
    cs <- comma space

    # basic tokens
    singleq <- [']
    doubleq <- ["]
    comma <- ','
    space <- '\s'
    colon <- ':'
    lparen <- '('
    rparen <- ')'
    langle <- '<'
    rangle <- '>'
    lbrace <- '{'
    rbrace <- '}'
    lbrack <- '['
    rbrack <- ']'
    fatarrow <- '=>'
    newline <- '\s'* '\n'

    # debug
    notnewline <- [^\n]*

    # private non-exported tokens.
    percent <- '%'
    bang <- '!'
    """,
    lineref: [export: true],
    clobbers: [export: true, post_traverse: :clobbers],
    keep: [post_traverse: :keep],
    clobber: [post_traverse: :clobber],
    int: [export: true, collect: true, post_traverse: :int],
    name: [export: true, collect: true],
    squoted: [export: true],
    dquoted: [export: true],
    dstring: [export: true, collect: true],
    cs: [ignore: true, export: true],
    singleq: [ignore: true, export: true],
    doubleq: [ignore: true, export: true],
    comma: [ignore: true, export: true],
    space: [ignore: true, export: true],
    colon: [ignore: true, export: true],
    lparen: [ignore: true, export: true],
    rparen: [ignore: true, export: true],
    langle: [ignore: true, export: true],
    rangle: [ignore: true, export: true],
    lbrace: [ignore: true, export: true],
    rbrace: [ignore: true, export: true],
    lbrack: [ignore: true, export: true],
    rbrack: [ignore: true, export: true],
    fatarrow: [ignore: true, export: true],
    newline: [ignore: true, export: true],
    notnewline: [export: true, collect: true],
    percent: [ignore: true],
    bang: [ignore: true]
  )

  defp int(rest, [value], context, _line, _bytes), do: {rest, [String.to_integer(value)], context}

  defp keep(rest, [line], context, _line, _bytes), do: {rest, [{line, :keep}], context}

  defp clobber(rest, [line], context, _line, _bytes), do: {rest, [{line, :clobber}], context}

  defp clobbers(rest, clobbers, context, _line, _bytes) do
    clobbers = clobbers
    |> Enum.map(fn {line, :clobber} -> line end)
    |> Enum.sort
    
    {rest, [{:clobbers, clobbers}], context}
  end
end
