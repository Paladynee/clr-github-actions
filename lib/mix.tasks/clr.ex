defmodule Mix.Tasks.Clr do
  use Mix.Task

  defstruct [:port, state: :pre, buffer: ""]

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

    loop(%__MODULE__{port: port})
  end

  def loop(%{port: port} = state) do
    receive do
      {^port, {:data, string}} ->
        state
        |> update(string)
        |> loop()

      {^port, {:exit_status, status}} ->
        status
    end
  end

  defp update(%{state: :pre} = state, string) do
    case string do
      "# Begin Function AIR:" <> _ ->
        update(%{state | state: :in}, string)

      _ ->
        %{state | state: :pre, buffer: state.buffer <> string}
    end
  end

  defp update(%{buffer: buffer, state: :in} = state, string) do
    updated = buffer <> string

    if updated =~ "# End Function AIR:" do
      updated
      |> String.split("\n")
      |> split_end([])
      |> case do
        {used, ""} ->
          analyze(used)
          %{state | state: :pre, buffer: ""}

        {used, new_buffer} ->
          analyze(used)
          %{state | state: :in, buffer: new_buffer}
      end
    else
      %{state | buffer: updated}
    end
  end

  defp split_end(["# End Function AIR:" <> _ = first | rest], so_far) do
    front = Enum.reverse(so_far, [first])
    {Enum.join(front, "\n"), Enum.join(rest, "\n")}
  end

  defp split_end([head | rest], so_far), do: split_end(rest, [head | so_far])

  defp analyze(content) do
    IO.puts(content)
    Clr.Air.parse(content)
  end
end
