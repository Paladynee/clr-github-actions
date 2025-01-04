defmodule ClrTest.FullIntegrationTest do
  use ExUnit.Case, async: true

  @moduletag :integration

  def assert_errors_with(msg, prefix) do
    assert_raise Mix.Error, msg, fn ->
      prefix
      |> then(&["run", Path.join("test/integration", &1)])
      |> Mix.Tasks.Clr.run()
    end
  end

  describe "undefined" do
    test "value used" do
      assert_errors_with(
        "Undefined value used in function `undefined_value_use.main` at 3:5",
        "undefined/undefined_value_use.zig"
      )
    end

    test "value passed and used" do
      assert_errors_with(
        "Undefined value used in function `undefined_value_passed.deref_ptr` at 2:3",
        "undefined/undefined_value_passed.zig"
      )
    end
  end

  describe "stack_ptr_escape" do
    test "escaping parameter pointer" do
      assert_errors_with(
        "Stack pointer escape detected in function `param_ptr_escape.escaped_param_ptr` at 2:3",
        "stack_ptr_escape/param_ptr_escape.zig"
      )
    end

    test "escaping stack variable pointer" do
      assert_errors_with(
        "Stack pointer escape detected in function `stack_ptr_escape.escaped_ptr` at 4:3",
        "stack_ptr_escape/stack_ptr_escape.zig"
      )
    end
  end

  describe "uaf/df" do
    test "use after free" do
      assert_errors_with(
        "Use after free detected in function `use_after_free.main` at 4:5",
        "uaf_df/use_after_free.zig"
      )
    end

    test "stack free" do
      assert_errors_with(
        "Stack memory attempted to be freed by `heap.c_allocator_vtable` in `stack_free.main` at 3:18",
        "uaf_df/stack_free.zig"
      )
    end

    test "double free" do
      assert_errors_with(
        "Double free detected in function `double_free.main` at 4:18",
        "uaf_df/double_free.zig"
      )
    end

    test "mismatched allocator" do
      assert_errors_with(
        "Heap memory allocated by `heap.PageAllocator.vtable` freed by `heap.c_allocator_vtable` in `mismatched_allocator.main` at 3:19",
        "uaf_df/mismatched_allocator.zig"
      )
    end
  end

  describe "leak" do
    test "leaked allocation"
  end

  describe "responsibility" do
    test "free_after_transfer" do
      assert_errors_with(
        "Free after transfer detected in function",
        "responsibility/free_after_transfer.zig"
      )
    end
  end
end
