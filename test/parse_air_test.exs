defmodule ParseAirTest do
  use ExUnit.Case, async: true

  alias Clr.Air
  alias Clr.Air.Function

  test "basic air text is a thing" do
    air = """
    # Begin Function AIR: start._start:
    # Total AIR+Liveness bytes: 517B
    # AIR Instructions:         17 (153B)
    # AIR Extra Data:           58 (232B)
    # Liveness tomb_bits:       16B
    # Liveness Extra Data:      1 (4B)
    # Liveness special table:   1 (8B)
      %0!= dbg_stmt(11:9)
      %4!= dbg_stmt(11:33)
      %5!= dbg_inline_block(void, <fn (Target.Cpu.Arch) callconv(.@"inline") bool, (function 'isRISCV')>, {
        %6!= dbg_arg_inline(<Target.Cpu.Arch, .x86_64>, "arch")
        %7!= dbg_stmt(2:13)
        %10!= br(%5, @Air.Inst.Ref.void_value)
      })
      %12!= dbg_stmt(25:5)
      %15!= assembly(void, volatile, [_start] in X = (<*const fn () callconv(.naked) noreturn, start._start>), [posixCallMainAndExit] in X = (<*const fn ([*]usize) callconv(.c) noreturn, start.posixCallMainAndExit>), " .cfi_undefined %%rip\\n xorl %%ebp, %%ebp\\n movq %%rsp, %%rdi\\n andq $-16, %%rsp\\n callq %[posixCallMainAndExit:P]")
      %16!= trap()
    # End Function AIR: start._start
    """

    assert %Function{name: "start._start"} = Air.parse(air)
  end
end
