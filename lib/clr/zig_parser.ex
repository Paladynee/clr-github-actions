defmodule Clr.Zig.Parser do
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

  def get(table \\ __MODULE__, lvalue) do
    case :ets.lookup(table, lvalue) do
      [{_, {path, location}}] -> {path, location}
      [] -> nil
    end
  end

  def dump(table \\ __MODULE__), do: :ets.tab2list(table)

  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  def init(opts) do
    opts
    |> Keyword.get(:name, __MODULE__)
    |> :ets.new([:named_table, :public])
    {:ok, [], :hibernate}
  end
end