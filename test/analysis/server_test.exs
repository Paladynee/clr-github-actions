defmodule ClrTest.Analysis.ServerTest do
  use ExUnit.Case, async: true

  alias Clr.Analysis
  alias ClrTest.AnalyzerMock

  # each test gets its own analysis server process.
  setup %{test: test} do
    table_name = :"test-analysis-server"
    server = start_supervised!({Analysis, [name: table_name, analyzer: AnalyzerMock]})
    Mox.allow(AnalyzerMock, self(), server)
    Process.put(Clr.Analysis.TableName, table_name)
    {:ok, server: server}
  end

  test "we can make a single evaluation request", %{server: server} do
    Mox.expect(AnalyzerMock, :do_evaluate, fn _, _ -> :result end)

    future = Analysis.evaluate(:foobar_function, [])
    assert :result = Analysis.await(future)
    assert :result = Analysis.debug_get_table(:foobar_function, []) 
  end
end
