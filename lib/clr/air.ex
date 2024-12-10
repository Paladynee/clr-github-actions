defmodule Clr.Air do
  alias Clr.Air.Parser

  defdelegate parse(text), to: Parser
end