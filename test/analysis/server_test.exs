defmodule ClrTest.Function.ServerTest do
  use ExUnit.Case, async: true

  alias Clr.Function
  alias ClrTest.AnalyzerMock

  # each test gets its own analysis server process.
  setup %{test: test} do
    table_name = :"#{test}-analysis-server"
    server = start_supervised!({Function, [name: table_name, analyzer: AnalyzerMock]})

    Mox.allow(AnalyzerMock, self(), server)
    Process.put(Clr.Function.TableName, table_name)
    {:ok, table: table_name}
  end

  defp ok_evaluation(type), do: {:ok, %Function{return: type, reqs: []}}

  test "we can make a single evaluation request" do
    Mox.expect(AnalyzerMock, :do_evaluate, fn _, _ -> ok_evaluation(:result) end)

    future = Function.evaluate(:foobar_function, [])
    assert {:ok, {:result, []}} = Function.await(future)
    assert {:ok, {:result, []}} = Function.debug_get_table(:foobar_function, [])
  end

  test "if content is in the table, it doesn't reevaluate" do
    Function.debug_insert_result(:foobar_function, [], {:ok, :result})
    {:ok, :result} = Function.evaluate(:foobar_function, [])
  end

  test "multiple evaluation requests can occur", %{table: table_name} do
    this = self()

    Mox.expect(AnalyzerMock, :do_evaluate, fn _, _ ->
      send(this, {:unblock, self()})
      assert_receive :unblock
      ok_evaluation(:result)
    end)

    future1 = Function.evaluate(:foobar_function, [])

    spawn(fn ->
      Process.put(Clr.Function.TableName, table_name)
      future2 = Function.evaluate(:foobar_function, [])
      send(this, :registered)
      assert {:ok, {:result, []}} = Function.await(future2)
      send(this, :done)
    end)

    assert_receive :registered

    receive do
      {:unblock, what} -> send(what, :unblock)
    end

    assert_receive :done, 500
    assert {:ok, {:result, []}} = Function.await(future1)
  end

  test "different args have different entries" do
    AnalyzerMock
    |> Mox.expect(:do_evaluate, fn :foobar_function, [:foo] -> ok_evaluation(:fooresult) end)
    |> Mox.expect(:do_evaluate, fn :foobar_function, [:bar] -> ok_evaluation(:barresult) end)

    foofuture = Function.evaluate(:foobar_function, [:foo])

    Process.sleep(100)

    barfuture = Function.evaluate(:foobar_function, [:bar])

    assert {:ok, {:fooresult, []}} = Function.await(foofuture)
    assert {:ok, {:barresult, []}} = Function.await(barfuture)
  end
end
