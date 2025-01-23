defmodule ClrTest.Function.ManagesTest do
  use ExUnit.Case, async: true

  @moduletag :skip

  alias Clr.Air.Function
  alias Clr.Block
  import Clr.Air.Lvalue

  defp run_analysis(code, args_meta) do
    %Function{name: ~l"foo.bar"}
    |> Block.new(args_meta)
    |> Block.analyze(code)
  end

  defp destructor(vtable, src, call) do
    {:literal,
     {:fn, [~l"mem.Allocator", :foobar], ~l"void",
      [{:literal, ~l"mem.Allocator", %{"vtable" => vtable}}, {src, :clobber}]}, {:function, call}}
  end

  describe "responsibility is marked as transferred" do
    test "when you pass a pointer to the function" do
      assert %{
               args_meta: [%{heap: ~l"my_vtable"}],
               reqs: [%{transferred: ~l"foo.bar"}]
             } =
               run_analysis(
                 %{
                   {0, :keep} => %Clr.Air.Instruction.Function.Arg{type: {:ptr, :one, ~l"u8", []}},
                   {1, :clobber} => %Clr.Air.Instruction.Function.Call{
                     fn: destructor(~l"my_vtable", 0, "destroy"),
                     args: [
                       {:literal, ~l"mem.Allocator", %{"vtable" => ~l"my_vtable"}},
                       {0, :clobber}
                     ]
                   }
                 },
                 [%{heap: ~l"my_vtable"}]
               )
    end
  end
end
