defmodule ClrTest.Integration.ZigParserTest do
  use ExUnit.Case, async: true

  alias Clr.Zig.Parser
  import Clr.Air.Lvalue

  setup t do
    Parser.start_link(name: t.test)
    :ok
  end

  test "allocator/free_after_transfer.zig", t do
    __DIR__
    |> Path.join("allocator/free_after_transfer.zig")
    |> File.read!()
    |> then(&Parser.load_parse(t.test, &1, "allocator/free_after_transfer.zig"))

    assert [
             {~l"free_after_transfer.function_deletes",
              {"allocator/free_after_transfer.zig", {3, _}}},
             {~l"free_after_transfer.main", {"allocator/free_after_transfer.zig", {7, _}}}
           ] =
             t.test
             |> Parser.dump()
             |> Enum.sort()
  end
end
