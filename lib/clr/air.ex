defmodule Clr.Air do
  alias Clr.Air.Parser

  defdelegate parse(text), to: Parser

  defmacro import(module, symbols) do
    quote bind_quoted: binding() do
      require NimbleParsec

      for symbol <- symbols do
        case symbol do
          {here, there} ->
            NimbleParsec.defparsecp(here, NimbleParsec.parsec({module, there}))

          _same ->
            NimbleParsec.defparsecp(symbol, NimbleParsec.parsec({module, symbol}))
        end
      end
    end
  end
end
