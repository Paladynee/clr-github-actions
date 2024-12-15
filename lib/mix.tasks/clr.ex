defmodule Mix.Tasks.Clr do
  use Mix.Task

  defmodule LineScanner do
    defstruct [:port, buffer: ""]
  end

  defmodule FunctionScanner do
    defstruct [active: false, name: nil, so_far: []]
  end

  @zig "/home/ityonemo/code/zig/zig-out/bin/zig"

  def run([file]) do
    file
    |> initializer
    |> Stream.resource(&loop/1, &cleanup/1)
    |> Enum.reduce(%FunctionScanner{}, &scan_function/2)
  end

  defp initializer(file) do
    port =
      :erlang.open_port({:spawn_executable, @zig}, [
        :binary,
        :stream,
        :exit_status,
        :use_stdio,
        :stderr_to_stdout,
        args: ~w[run --verbose-air #{file}]
      ])

    fn -> %LineScanner{port: port} end
  end

  defp loop(%{port: port} = state) do
    receive do
      {^port, {:data, string}} ->
        scan_buf(state, string)

      {^port, {:exit_status, status}} ->
        {[state.buffer <> "\n"], {:halt, status}}
    end
  end

  defp loop({:halt, status}), do: {:halt, status}

  defp scan_buf(state, string) do
    scan_string = state.buffer <> string
    {start, _, so_far} =
      for <<byte <- scan_string>>, reduce: {0, 0, []} do
        {start, this, so_far} when byte == ?\n ->
          line = :erlang.binary_part(scan_string, start, this - start)
          {this + 1, this + 1, [line | so_far]}

        {start, this, so_far} ->
          {start, this + 1, so_far}
      end

    {_, new_buff} = :erlang.split_binary(scan_string, start)

    {Enum.reverse(so_far), %{state | buffer: new_buff}} 
  end

  defp cleanup(_), do: :ok

  defp scan_function("# Begin Function AIR: " <> name = line, %{active: false} = state) do
    name = name
    |> String.split(":")
    |> List.first()

    %{state | active: true, so_far: [line], name: name}
  end

  defp scan_function("# Begin Function AIR: " <> name, _) do
    Mix.raise("unexpected start of function #{name}")
  end

  defp scan_function("# End Function AIR: " <> name = line, %{active: true} = state) do
    if String.starts_with?(name, state.name) do
      Enum.reverse([line | state.so_far]) |> IO.puts()
    else
      Mix.raise("name mismatch (#{name}, #{state.name})")
    end
    %FunctionScanner{}
  end

  defp scan_function("# End Function AIR: " <> name, _) do
    Mix.raise("unexpected end of function #{name}")
  end

  @emptylines ["\n", ""]

  defp scan_function(empty, %{active: false} = state) when empty in @emptylines, do: state

  defp scan_function(line, %{active: false}) do
    Mix.raise("unexpected line #{inspect line}")
  end

  defp scan_function(line, state) do
    Map.update!(state, :so_far, &[line | &1])
  end
end
