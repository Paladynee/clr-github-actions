defmodule ClrTest.FunctionTest do
  use ExUnit.Case, async: true

  # tests the

  alias Clr.Block
  alias Clr.Function
  alias ClrTest.AnalyzerMock

  import Clr.Air.Lvalue

  # each test gets its own analysis server process.
  setup %{test: test} do
    table_name = :"#{test}-analysis-server"
    server = start_supervised!({Function, [name: table_name, analyzer: AnalyzerMock]})

    Mox.allow(AnalyzerMock, self(), server)
    Process.put(Clr.Function.TableName, table_name)
    {:ok, table: table_name}
  end

  defp ok_evaluation(type),
    do: {:ok, %Block{function: ~l"foo.bar", return: type, args_meta: [], reqs: []}}

  test "we can make a single evaluation request" do
    Mox.expect(AnalyzerMock, :do_evaluate, fn _, _ -> ok_evaluation(:result) end)

    {:future, future} = Function.evaluate(:foobar_function, [], [])
    assert {:ok, {:result, lambda1}} = Function.await(future)
    # this is the function that can add metadata to slots.
    assert is_function(lambda1, 1)

    assert {:result, lambda2} = Function.debug_get_table(:foobar_function, [])
    # this is a lambda that takes a block and 
    assert is_function(lambda2, 2)
  end

  def empty_lambda(block, _args), do: block

  test "if content is in the table, it doesn't reevaluate" do
    Function.debug_insert_result(:foobar_function, [], {:result, &empty_lambda/2})
    {:result, lambda} = Function.evaluate(:foobar_function, [], [])
    assert is_function(lambda, 1)
  end

  test "multiple evaluation requests can occur", %{table: table_name} do
    this = self()

    Mox.expect(AnalyzerMock, :do_evaluate, fn _, _ ->
      send(this, {:unblock, self()})
      assert_receive :unblock
      ok_evaluation(:result)
    end)

    {:future, future1} = Function.evaluate(:foobar_function, [], [])

    spawn(fn ->
      Process.put(Clr.Function.TableName, table_name)
      {:future, future2} = Function.evaluate(:foobar_function, [], [])
      send(this, :registered)
      assert {:ok, {:result, lambda}} = Function.await(future2)
      assert is_function(lambda, 1)
      send(this, :done)
    end)

    assert_receive :registered

    receive do
      {:unblock, what} -> send(what, :unblock)
    end

    assert_receive :done, 500
    assert {:ok, {:result, lambda}} = Function.await(future1)
    assert is_function(lambda, 1)
  end

  test "different args have different entries" do
    AnalyzerMock
    |> Mox.expect(:do_evaluate, fn :foobar_function, [%{foo: :bar}] ->
      ok_evaluation(:fooresult)
    end)
    |> Mox.expect(:do_evaluate, fn :foobar_function, [%{bar: :baz}] ->
      ok_evaluation(:barresult)
    end)

    {:future, foofuture} = Function.evaluate(:foobar_function, [%{foo: :bar}], [1])

    Process.sleep(100)

    {:future, barfuture} = Function.evaluate(:foobar_function, [%{bar: :baz}], [1])

    assert {:ok, {:fooresult, function1}} = Function.await(foofuture)
    assert is_function(function1, 1)
    assert {:ok, {:barresult, function2}} = Function.await(barfuture)
    assert is_function(function2, 1)

    assert [
             {{:foobar_function, [%{bar: :baz}]}, {:barresult, _}},
             {{:foobar_function, [%{foo: :bar}]}, {:fooresult, _}}
           ] = Enum.sort(Function.debug_get_table())
  end
end
