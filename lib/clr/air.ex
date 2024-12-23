defmodule Clr.Air do
  alias Clr.Air.Parser

  defdelegate parse(text), to: Parser

  @base ~w[lineref clobbers keep clobber squoted dquoted dstring identifier alpha alnum int cs singleq doubleq comma space colon dot 
           lparen rparen langle rangle lbrace rbrace lbrack rbrack fatarrow newline equals null undefined elision notnewline]a

  @literal ~w[literal fn_literal convertible enum_value]a

  @lvalue ~w[lvalue comptime_struct]a

  @type_ ~w[type fn_type ptr_type enum_literal]a

  @parser ~w[codeline codeblock codeblock_clobbers]a

  @instruction ~w[instruction argument]a

  defmacro import(symbols) do
    symbol_map =
      symbols
      |> Macro.expand(__CALLER__)
      |> Enum.map(fn
        symbol when symbol in @base -> {symbol, Clr.Air.Base}
        symbol when symbol in @literal -> {symbol, Clr.Air.Literal}
        symbol when symbol in @lvalue -> {symbol, Clr.Air.Lvalue}
        symbol when symbol in @type_ -> {symbol, Clr.Air.Type}
        symbol when symbol in @parser -> {symbol, Clr.Air.Parser}
        symbol when symbol in @instruction -> {symbol, Clr.Air.Instruction}
      end)

    quote bind_quoted: [symbol_map: symbol_map] do
      require NimbleParsec

      for {symbol, module} <- symbol_map do
        NimbleParsec.defparsecp(symbol, NimbleParsec.parsec({module, symbol}))
      end
    end
  end
end
