defmodule Clr.Air.Base do
  # basic parser and parser combinators for AIR parsing

  require Pegasus

  Pegasus.parser_from_string(
    """
    name <- [0-9a-zA-Z._@] +

    cs <- comma space

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
    arrow <- '=>'
    newline <- '\s'* '\n'
    """,
    name: [export: true, collect: true],
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
    arrow: [ignore: true, export: true],
    newline: [ignore: true, export: true]
  )
end