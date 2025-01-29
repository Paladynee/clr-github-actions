defmodule Mix.Tasks.Clr do
  use Mix.Task

  defmodule LineScanner do
    defstruct [:port, buffer: ""]
  end

  defmodule FunctionScanner do
    defstruct active: false, name: nil, await_refs: [], so_far: [], start_functions: []
  end

  @zig "/home/ityonemo/code/zig/zig-out/bin/zig"

  def run([cmd, file]) do
    Process.flag(:trap_exit, true)
    # start the AIR server
    Clr.Air.start_link([])
    # start the analysis server
    Clr.Function.start_link([])
    # start the parser database
    Clr.Zig.Parser.start_link([])

    Clr.Zig.Parser.load_parse(file)

    # initialize which checkers to activate
    Clr.set_checkers([
      Clr.Analysis.Undefined,
      Clr.Analysis.StackPointer,
      Clr.Analysis.Allocator,
      Clr.Analysis.Unit
    ])

    if System.get_env("DEBUG", "false") == "true" do
      Application.put_env(:clr, :debug_prefix, Path.basename(file, ".zig"))
    end

    start_functions =
      case cmd do
        "run" -> run_functions(file)
      end

    scanner =
      cmd
      |> initializer(file)
      |> Stream.resource(&loop/1, &cleanup/1)
      |> Enum.reduce(%FunctionScanner{start_functions: start_functions}, &scan_function/2)

    Enum.each(scanner.await_refs, fn {:future, ref} ->
      case Clr.Function.await(ref) do
        {:error, {error, _stacktrace}} when is_exception(error) ->
          error
          |> Exception.message()
          |> Mix.raise()

        {:error, error} ->
          error
          |> then(&Exception.normalize(:error, &1))
          |> Exception.message()
          |> Mix.raise()

        _ok ->
          :ok
      end
    end)
  end

  defp run_functions(file) do
    base = Path.basename(file, ".zig")
    [lvalue: [base, "main"]]
  end

  defp initializer(cmd, file) do
    port =
      :erlang.open_port({:spawn_executable, @zig}, [
        :binary,
        :stream,
        :exit_status,
        :use_stdio,
        :stderr_to_stdout,
        args: [cmd, "--verbose-air", "-lc", file]
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
          line = :erlang.binary_part(scan_string, start, this - start + 1)
          {this + 1, this + 1, [line | so_far]}

        {start, this, so_far} ->
          {start, this + 1, so_far}
      end

    {_, new_buff} = :erlang.split_binary(scan_string, start)

    {Enum.reverse(so_far), %{state | buffer: new_buff}}
  end

  defp cleanup(_), do: :ok

  defp scan_function("# Begin Function AIR: " <> name = line, %{active: false} = state) do
    name =
      name
      |> String.split(":")
      |> List.first()

    %{state | active: true, so_far: [line], name: name}
  end

  defp scan_function("# Begin Function AIR: " <> name, _) do
    Mix.raise("unexpected start of function #{name}")
  end

  defp scan_function("# End Function AIR: " <> name = line, %{active: true} = state) do
    if String.starts_with?(name, state.name) do
      function = Enum.reverse([line | state.so_far])

      function
      |> IO.iodata_to_binary()
      |> Clr.Air.Function.parse()
      |> Clr.Air.put()
      |> maybe_trigger(state.start_functions)
      |> case do
        {:future, _} = future ->
          %{state | name: nil, active: false, await_refs: [future | state.await_refs]}

        _ ->
          %{state | name: nil, active: false}
      end
    else
      Mix.raise("name mismatch (#{name}, #{state.name})")
    end
  end

  defp scan_function("# End Function AIR: " <> name, _) do
    Mix.raise("unexpected end of function #{name}")
  end

  @emptylines ["\n", ""]

  defp scan_function(empty, %{active: false} = state) when empty in @emptylines, do: state

  defp scan_function(line, %{active: false} = state) do
    # these lines appear after the parser has completed
    IO.write(:stdio, line)
    state
  end

  defp scan_function(line, state) do
    Map.update!(state, :so_far, &[line | &1])
  end

  defp maybe_trigger(function, start_functions) do
    # TODO: start_functions should come with their intended CLR information
    if function.name in start_functions do
      # we don't actually care what the return values of these guys are.
      Clr.Function.evaluate(function.name, [], [], nil)
    end
  end
end
