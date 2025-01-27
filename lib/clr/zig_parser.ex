defmodule Clr.Zig.Parser do
  alias Clr.Air.Lvalue

  def load_parse(path) do
    path
    |> File.read!()
    |> then(&load_parse(__MODULE__, &1, path))
  end

  def load_parse(table \\ __MODULE__, code, path) do
    basename = Path.basename(path, ".zig")
    code = Zig.Parser.parse(code).code

    code
    |> Enum.filter(&is_struct(&1, Zig.Parser.Function))
    |> Enum.map(fn function ->
      {{:lvalue, [basename, "#{function.name}"]}, {path, function.location}}
    end)
    |> then(&:ets.insert(table, &1))

    :ok
  end

  def debug_put(table \\ __MODULE__, lvalue, path, location) do
    :ets.insert(table, {lvalue, {path, location}})
  end

  def get(table \\ __MODULE__, lvalue) do
    case :ets.lookup(table, lvalue) do
      [{_, {path, location}}] -> {path, location}
      [] -> nil
    end
  end

  def dump(table \\ __MODULE__), do: :ets.tab2list(table)

  def format_location(lvalue, {:arg, index}) do
    {abs_path, {line, _}} = get(lvalue)
    rel_path = Path.relative_to_cwd(abs_path)

    "function #{Lvalue.as_string(lvalue)} (#{rel_path}:#{line}, argument #{index})"
  rescue
    _ -> "function #{Lvalue.as_string(lvalue)} (argument: #{index})"
  end

  def format_location(lvalue, {row, col}) do
    {abs_path, {line, _}} = get(lvalue)
    rel_path = Path.relative_to_cwd(abs_path)

    "function #{Lvalue.as_string(lvalue)} (#{rel_path}:#{row + line - 1}:#{col})"
  rescue
    _ -> "function #{Lvalue.as_string(lvalue)} {#{row}:#{col}}"
  end

  use GenServer

  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))

  def init(opts) do
    opts
    |> Keyword.get(:name, __MODULE__)
    |> :ets.new([:named_table, :public])

    {:ok, [], :hibernate}
  end
end
