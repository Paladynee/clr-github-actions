defmodule ParseAirTest do
  use ExUnit.Case, async: true

  import ClrTest.TestAir

  test_air("start._start")

  test_air("start.posixCallMainAndExit")

  test_air("os.linux.tls.initStatic")

  test_air("start.expandStackSize")

  test_air("debug.FormattedPanic.startGreaterThanEnd")

  test_air("debug.defaultPanic")

  test_air("debug.getSelfDebugInfo")

  test_air("posix.dl_iterate_phdr__anon_4201")

  test_air("stack_ptr_escape.escaped_ptr")
end
