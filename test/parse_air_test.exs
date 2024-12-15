defmodule ParseAirTest do
  use ExUnit.Case, async: true

  import ClrTest.TestAir

  alias Clr.Air
  alias Clr.Air.Function

  test_air("start._start")

  test_air("start.posixCallMainAndExit")

  test_air("os.linux.tls.initStatic")

  test_air("start.expandStackSize")

  test_air("debug.FormattedPanic.startGreaterThanEnd")
end
