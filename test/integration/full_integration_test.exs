defmodule ClrTest.FullIntegrationTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  alias Clr.Zig.Parser

  @file_colon Path.relative_to_cwd(__ENV__.file) <> ":"

  def assert_errors_with(msg, prefix) do
    if match?([_, @file_colon <> _], System.argv()) do
      Application.put_env(:clr, :debug_prefix, Path.basename(prefix, ".zig"))
    end

    assert_raise Mix.Error, msg, fn ->
      prefix
      |> then(&["run", Path.join("test/integration", &1)])
      |> Mix.Tasks.Clr.run()
    end
  end

  describe "undefined" do
    test "value used" do
      "undefined/undefined_value_use.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Use of undefined value in function undefined_value_use.main (test/integration/undefined/undefined_value_use.zig:3:5).
        Value was set undefined in function undefined_value_use.main (test/integration/undefined/undefined_value_use.zig:2:5)
        """,
        "undefined/undefined_value_use.zig"
      )
    end

    test "value passed and used" do
      "undefined/undefined_value_passed.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Use of undefined value in function undefined_value_passed.deref_ptr (test/integration/undefined/undefined_value_passed.zig:2:3).
        Value was set undefined in function undefined_value_passed.main (test/integration/undefined/undefined_value_passed.zig:6:5)
        """,
        "undefined/undefined_value_passed.zig"
      )
    end
  end

  describe "stack_pointer" do
    test "escaping parameter pointer" do
      "stack_pointer/param_ptr_escape.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Escape of stack pointer in function param_ptr_escape.escaped_param_ptr (test/integration/stack_pointer/param_ptr_escape.zig:2:3).
        Value was created in function param_ptr_escape.escaped_param_ptr (test/integration/stack_pointer/param_ptr_escape.zig:1, argument 0)
        """,
        "stack_pointer/param_ptr_escape.zig"
      )
    end

    test "escaping stack variable pointer" do
      "stack_pointer/stack_ptr_escape.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Escape of stack pointer in function stack_ptr_escape.escaped_ptr (test/integration/stack_pointer/stack_ptr_escape.zig:4:3).
        Value was created in function stack_ptr_escape.escaped_ptr (test/integration/stack_pointer/stack_ptr_escape.zig:2:3)
        """,
        "stack_pointer/stack_ptr_escape.zig"
      )
    end
  end

  describe "allocator" do
    test "use after free" do
      "allocator/use_after_free.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Use after free detected in function use_after_free.main (test/integration/allocator/use_after_free.zig:7:5).
        Pointer was deleted in function use_after_free.main (test/integration/allocator/use_after_free.zig:6:18)
        """,
        "allocator/use_after_free.zig"
      )
    end

    test "stack free" do
      "allocator/stack_free.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Stack memory attempted to be freed by allocator `heap.c_allocator_vtable in function stack_free.main (test/integration/allocator/stack_free.zig:5:18).
        Pointer was created in function stack_free.main (test/integration/allocator/stack_free.zig:4:5)
        """,
        "allocator/stack_free.zig"
      )
    end

    test "double free" do
      "allocator/double_free.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Double free detected in function double_free.main (test/integration/allocator/double_free.zig:6:18).
        Previously deleted in function double_free.main (test/integration/allocator/double_free.zig:5:18)
        """,
        "allocator/double_free.zig"
      )
    end

    test "mismatched allocator" do
      "allocator/mismatched_allocator.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Heap memory attempted to be freed by `heap.c_allocator_vtable` in function mismatched_allocator.main (test/integration/allocator/mismatched_allocator.zig:6:19).
        Originally allocated by `heap.PageAllocator.vtable`
        """,
        "allocator/mismatched_allocator.zig"
      )
    end

    @tag :skip
    test "call with deleted"

    @tag :skip
    test "transfer to global"

    @tag :skip
    test "linked list on heap"
  end

  describe "leak" do
    test "leaked allocation"
  end

  describe "responsibility" do
    test "free_after_transfer" do
      assert_errors_with(
        """
        Double free detected in function free_after_transfer.main (test/integration/allocator/free_after_transfer.zig:10:18).
        Previously deleted in function free_after_transfer.function_deletes (test/integration/allocator/free_after_transfer.zig:4:18)
        """,
        "allocator/free_after_transfer.zig"
      )
    end
  end

  describe "units" do
    test "mismatch" do
      "units/unit_conflict.zig"
      |> then(&Path.join(__DIR__, &1))
      |> Parser.load_parse()

      assert_errors_with(
        """
        Mismatched units found in function unit_conflict.main (test/integration/units/unit_conflict.zig:27:15).
        Left hand side: m/s
        Right hand side: ft/s
        """, "units/unit_conflict.zig")
    end
  end
end
