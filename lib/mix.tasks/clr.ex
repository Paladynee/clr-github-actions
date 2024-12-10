defmodule Mix.Tasks.Clr do
  use Mix.Task

  @zig "/home/ityonemo/code/zig/zig-out/bin/zig"

  def run([file]) do
    port =
      :erlang.open_port({:spawn_executable, @zig}, [
        :binary,
        :stream,
        :exit_status,
        :use_stdio,
        :stderr_to_stdout,
        args: ~w[run --verbose-air #{file}]
      ])

    loop(port, 100)
  end

  def loop(port, count) do
    if count == 0, do: raise "done"
    receive do
      {^port, {:data, what}} ->
        IO.write(:stdio, what)
        loop(port, count - 1)

      {^port, {:exit_status, status}} ->
        status
    end
  end
end
