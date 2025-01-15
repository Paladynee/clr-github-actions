defmodule ClrTest.TypeTest do
  use ExUnit.Case, async: true

  alias Clr.Type

  test "unsigned integer type" do
    assert Type.valid?({:u, 8, %{}})
  end

  test "pointer type" do
    assert Type.valid?(
             {:ptr, :one, {:u, 8, %{}}, %{stack: {:lvalue, ["undefined_value_use", "main"]}}}
           )
  end
end
