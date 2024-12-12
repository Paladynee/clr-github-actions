defmodule Clr.Air do
  alias Clr.Air.Parser

  defdelegate parse(text), to: Parser

  defmacro import(module, symbols) do
    quote bind_quoted: binding() do
      require NimbleParsec
      for symbol <- symbols do
        NimbleParsec.defparsecp(symbol, NimbleParsec.parsec({module, symbol}))
      end
    end
  end
end
