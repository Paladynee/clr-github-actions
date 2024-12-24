defmodule ClrTest.AirParsers.AtomicsTests do
  use ExUnit.Case, async: true

  import Clr.Air.Lvalue

  alias Clr.Air.Instruction

  alias Clr.Air.Instruction.Atomics.Rmw

  test "atomic_rmw" do
    assert %Rmw{
             loc: {:literal, {:ptr, :one, ~l"u8", []}, ~l"debug.panicking.raw"},
             mode: :seq_cst,
             op: :add,
             val: ~l"@Air.Inst.Ref.one_u8"
           } =
             Instruction.parse(
               "atomic_rmw(<*u8, debug.panicking.raw>, @Air.Inst.Ref.one_u8, Add, seq_cst)"
             )
  end

  alias Clr.Air.Instruction.Atomics.Load

  test "atomic_load" do
    assert %Load{from: {13, :clobber}, mode: :unordered} =
      Instruction.parse("atomic_load(%13!, unordered)")
  end

  alias Clr.Air.Instruction.Atomics.Store

  test "atomic_store_unordered" do
    assert %Store{to: {0, :keep}, from: {13, :clobber}, mode: :unordered} =
             Instruction.parse("atomic_store_unordered(%0, %13!, unordered)")
  end

  test "atomic_store_monotonic" do
    assert %Store{
             to: {:literal, {:ptr, :one, ~l"i32", []}, ~l"debug.MemoryAccessor.cached_pid"},
             from: {28, :keep},
             mode: :monotonic
           } =
             Instruction.parse(
               "atomic_store_monotonic(<*i32, debug.MemoryAccessor.cached_pid>, %28, monotonic)"
             )
  end

  alias Clr.Air.Instruction.Atomics.Cmpxchg

  test "cmpxchg_weak" do
    assert %Cmpxchg{
             loc: {:literal, {:ptr, :one, ~l"bool", []}, ~l"posix.abort.global.abort_entered"},
             expected: ~l"@Air.Inst.Ref.bool_false",
             desired: ~l"@Air.Inst.Ref.bool_true",
             success_mode: :seq_cst,
             failure_mode: :seq_cst
           } =
             Instruction.parse(
               "cmpxchg_weak(<*bool, posix.abort.global.abort_entered>, @Air.Inst.Ref.bool_false, @Air.Inst.Ref.bool_true, seq_cst, seq_cst)"
             )
  end

  # test "cmpxchg_strong" do
  #  assert %CmpxchgStrong{
  #           loc:
  #             {:literal,
  #              {:ptr, :one, {:ptr, :many, ~l"u8", [optional: true, alignment: 4096]}, []},
  #              ~l"heap.next_mmap_addr_hint"},
  #           expected: {28, :clobber},
  #           desired: {70, :clobber},
  #           success_mode: :monotonic,
  #           failure_mode: :monotonic
  #         } =
  #           Instruction.parse(
  #             "cmpxchg_strong(<*?[*]align(4096) u8, heap.next_mmap_addr_hint>, %28!, %70!, monotonic, monotonic)"
  #           )
  # end
end
