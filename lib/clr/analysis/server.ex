defmodule Clr.Analysis.Server do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    :ets.new(__MODULE__, [:named_table, :set, :public])
    {:ok, [], :hibernate}
  end
end
