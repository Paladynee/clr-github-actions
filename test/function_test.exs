defmodule ClrTest.FunctionTest do
  use ExUnit.Case, async: true

  # tests the

  alias Clr.Block
  alias Clr.Function
  alias ClrTest.AnalyzerMock

  import Clr.Air.Lvalue
  import Mox

  setup :verify_on_exit!

  setup %{test: test} do
    table_name = :"#{test}-function-table"
    server = start_supervised!({Function, [name: table_name, analyzer: AnalyzerMock]})

    Mox.allow(AnalyzerMock, self(), server)
    Process.put(Clr.Function.TableName, table_name)
    Clr.Air.put(%Clr.Air.Function{name: ~l"foobar"})
    {:ok, table: table_name}
  end

  defp stub_eval(type), do: %Block{function: ~l"foo.bar", return: type, args: []}

  test "we can make a single evaluation request" do
    Mox.expect(AnalyzerMock, :analyze, fn _, _ -> stub_eval(:result) end)

    {:future, future} = Function.evaluate(~l"foobar", 1, [], [], :void)
    assert {:ok, {:result, lambda1}} = Function.await(future)
    # this is the function that can add metadata to slots.
    assert is_function(lambda1, 1)
    assert {%{return: :result}, lambda2} = Function.debug_get_table(~l"foobar", [])
    assert is_function(lambda2, 3)
  end

  def empty_lambda(block, _args), do: block

  test "if content is in the table, it doesn't reevaluate" do
    Function.debug_insert_result(~l"foobar", [], {:result, &empty_lambda/2})
    {:result, lambda} = Function.evaluate(~l"foobar", 1, [], [], :void)
    assert is_function(lambda, 1)
  end

  test "multiple evaluation requests can occur", %{table: table_name} do
    this = self()

    Mox.expect(AnalyzerMock, :analyze, fn _, _ ->
      Process.sleep(50)
      send(this, {:unblock, self()})
      assert_receive :unblock
      stub_eval(:result)
    end)

    {:future, future1} = Function.evaluate(~l"foobar", 1, [], [], :void)

    spawn(fn ->
      Process.put(Clr.Function.TableName, table_name)
      {:future, future2} = Function.evaluate(~l"foobar", 1, [], [], :void)
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

  test "different metadata have different entries" do
    AnalyzerMock
    |> Mox.expect(:analyze, fn %{args: [%{foo: :bar}]}, _ ->
      stub_eval(:fooresult)
    end)
    |> Mox.expect(:analyze, fn %{args: [%{bar: :baz}]}, _ ->
      stub_eval(:barresult)
    end)

    {:future, foofuture} = Function.evaluate(~l"foobar", 1, [%{foo: :bar}], [1], :void)

    Process.sleep(100)

    {:future, barfuture} = Function.evaluate(~l"foobar", 1, [%{bar: :baz}], [1], :void)

    assert {:ok, {:fooresult, function1}} = Function.await(foofuture)
    assert is_function(function1, 1)
    assert {:ok, {:barresult, function2}} = Function.await(barfuture)
    assert is_function(function2, 1)

    assert [
             {{~l"foobar", [%{bar: :baz}]}, {%Block{return: :barresult}, _}},
             {{~l"foobar", [%{foo: :bar}]}, {%Block{return: :fooresult}, _}}
           ] = Enum.sort(Function.debug_get_table())
  end
end
