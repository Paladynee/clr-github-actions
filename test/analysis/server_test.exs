defmodule ClrTest.Analysis.ServerTest do
  use ExUnit.Case, async: true

  alias Clr.Analysis
  alias ClrTest.AnalyzerMock

  # each test gets its own analysis server process.
  setup %{test: test} do
    table_name = :"#{test}-analysis-server"
    server = start_supervised!({Analysis, [name: table_name, analyzer: AnalyzerMock]})
    Mox.allow(AnalyzerMock, self(), server)
    Process.put(Clr.Analysis.TableName, table_name)
    {:ok, table: table_name}
  end

  test "we can make a single evaluation request" do
    Mox.expect(AnalyzerMock, :do_evaluate, fn _, _ -> {:ok, :result} end)

    future = Analysis.evaluate(:foobar_function, [])
    assert {:ok, :result} = Analysis.await(future)
    assert {:ok, :result} = Analysis.debug_get_table(:foobar_function, [])
  end

  test "if content is in the table, it doesn't reevaluate" do
    Analysis.debug_insert_result(:foobar_function, [], {:ok, :result})
    {:ok, :result} = Analysis.evaluate(:foobar_function, [])
  end

  test "multiple evaluation requests can occur", %{table: table_name} do
    this = self()

    Mox.expect(AnalyzerMock, :do_evaluate, fn _, _ ->
      send(this, {:unblock, self()})
      assert_receive :unblock
      {:ok, :result}
    end)

    future1 = Analysis.evaluate(:foobar_function, [])

    spawn(fn ->
      Process.put(Clr.Analysis.TableName, table_name)
      future2 = Analysis.evaluate(:foobar_function, [])
      send(this, :registered)
      assert {:ok, :result} = Analysis.await(future2)
      send(this, :done)
    end)

    assert_receive :registered

    receive do
      {:unblock, what} -> send(what, :unblock)
    end

    assert_receive :done, 500
    assert {:ok, :result} = Analysis.await(future1)
  end

  test "different args have different entries" do
    AnalyzerMock
    |> Mox.expect(:do_evaluate, fn :foobar_function, [:foo] -> {:ok, :result1} end)
    |> Mox.expect(:do_evaluate, fn :foobar_function, [:bar] -> {:ok, :result2} end)

    future1 = Analysis.evaluate(:foobar_function, [:foo])
    future2 = Analysis.evaluate(:foobar_function, [:bar])

    assert {:ok, :result1} = Analysis.await(future1)
    assert {:ok, :result2} = Analysis.await(future2)
  end
end
