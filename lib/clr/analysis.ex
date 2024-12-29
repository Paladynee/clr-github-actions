defmodule Clr.Analysis do
  @moduledoc false

  # stores evaluated AIR functions in an ets table for retrieval.
  # if you make a request to evaluate an AIR function, the server will check if
  # it has already been evaluated.  If it hasn't, then, it will trigger evaluation
  # and store the result in the ets table.

  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @type waiter_id :: {name :: term, args :: []}
  @type waiters :: %{optional(waiter_id) => {[pid], future_ref :: reference}}
  @spec init([]) :: {:ok, waiters, :hibernate}

  def init(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    # allow for analyzer dependency injection here.
    analyzer = Keyword.get(opts, :analyzer, __MODULE__)
    Process.put(:analyzer, analyzer)
    Process.put(Clr.Analysis.TableName, name)

    :ets.new(name, [:named_table, :set, :public])
    {:ok, %{}, :hibernate}
  end

  def evaluate(function_name, args) do
    case :ets.lookup(table_name(), {function_name, args}) do
      [{_, result}] -> result
      [] -> GenServer.call(table_name(), {:evaluate, function_name, args})
    end
  end

  defp evaluate_impl(function_name, args, {pid, _ref}, waiters) do
    case Map.fetch(waiters, function_name) do
      {:ok, {pids, future}} ->
        {:reply, future, Map.replace!(waiters, {function_name, args}, {[pid | pids], future})}

      :error ->
        # do the evaluation here.  Response is obtained as a Task.async response.
        analyzer = Process.get(:analyzer)

        future =
          Task.async(fn ->
            analyzer.do_evaluate(function_name, args)
          end)

        {:reply, {:future, future.ref}, Map.put(waiters, {function_name, args}, {[pid], future.ref})}
    end
  end

  def do_evaluate(_, _) do
    raise "unimplemented"
  end

  def debug_get_table(function_name, args) do
    [{_, result}] = :ets.lookup(table_name(), {function_name, args})
    
    result
  end

  def await({:future, ref}) do
    receive do
      {ref, result} -> result
    end
  end

  def handle_call({:evaluate, function_name, args}, from, waiters),
    do: evaluate_impl(function_name, args, from, waiters)

  def handle_info({ref, result} = response, waiters) when is_reference(ref) do
    function_call =
      Enum.find(waiters, fn
        {function_call, {pids, ^ref}} ->
          # clean up the DOWN message
          receive do
            {:DOWN, ^ref, :process, _, reason} -> :ok
          end

          # stash the result in the table.
          :ets.insert(table_name(), {function_call, result})

          # forward the result to the pids
          Enum.each(pids, &send(&1, response))
          function_call
      end)

    {:noreply, Map.delete(waiters, function_call)}
  end

  # common utility functions
  def table_name do
    Process.get(Clr.Analysis.TableName, __MODULE__)
  end
end

#  def analyze(function_name, arguments) do
#    # walk the function code and analyze it
#    function_name
#    |> Clr.Air.Server.get()
#    |> do_analyze(arguments)
#  end
#
#  def do_analyze(function, arguments) do
#    Enum.reduce(
#      function.code,
#      %__MODULE__{name: function.name, arguments: arguments},
#      &analysis/2
#    )
#  end
#
#  # values that are clobbered can be safely ignored.
#  defp analysis({{_, :clobber}, _}, state), do: state
#
#  defp analysis({{line, :keep}, function}, state) do
#    {result, _param_type_changes} = Clr.Air.Instruction.analyze(function, state)
#    %{state | types: Map.put(state.types, line, result)}
#  end
# end
