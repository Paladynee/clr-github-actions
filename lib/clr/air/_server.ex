defmodule Clr.Air.Server do
  @moduledoc false

  # TODO: move into `Clr.Air` module

  # stores parsed AIR functions in an ets table for retrieval.  If you make
  # a request for a function that doesn't exist yet, the gen_server will 
  # register that the request has been made and then it will be able to
  # complete the callback when the function has been stored.

  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    :ets.new(__MODULE__, [:named_table, :set, :protected])
    {:ok, %{}}
  end

  def put(function) do
    GenServer.call(__MODULE__, {:put, function})
    function
  end

  defp put_impl(function, _from, state) do
    :ets.insert(__MODULE__, {function.name, function})

    case Map.fetch(state, function.name) do
      {:ok, waiters} ->
        Enum.each(waiters, &GenServer.reply(&1, function))
        {:reply, :ok, Map.delete(state, function.name)}

      :error ->
        {:reply, :ok, state}
    end
  end

  def get(function_name) do
    case :ets.lookup(__MODULE__, function_name) do
      [{^function_name, stored}] -> stored
      [] -> GenServer.call(__MODULE__, {:get, function_name}, :infinity)
    end
  end

  defp get_impl(function, from, state) do
    case Map.fetch(state, function) do
      {:ok, waiters} ->
        {:noreply, Map.put(state, function, [from | waiters])}

      :error ->
        {:noreply, Map.put(state, function, [from])}
    end
  end

  def handle_call({:put, function}, from, state), do: put_impl(function, from, state)
  def handle_call({:get, function_name}, from, state), do: get_impl(function_name, from, state)
end
