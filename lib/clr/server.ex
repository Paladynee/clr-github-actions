defmodule Clr.Server do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    :ets.new(__MODULE__, [:named_table, :set, :public])
    {:ok, [], :hibernate}
  end

  def store_function(function) do
    :ets.insert(__MODULE__, {function.name, function})

    function
  end

  def get_function(function) do
    :ets.lookup(__MODULE__, function) |> dbg(limit: 25)
  end
end