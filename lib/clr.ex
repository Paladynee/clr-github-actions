defmodule Clr do
  def debug_prefix, do: Application.get_env(:clr, :debug_prefix)

  @spec set_checkers([module]) :: :ok
  def set_checkers(checkers) do
    checkers = checkers ++ [Clr.Air.Instruction]
    Application.put_env(:clr, :checkers, checkers)

    instruction_mapper =
      for checker <- checkers, reduce: %{} do
        map ->
          checker.always()
          |> Enum.reduce(map, fn instruction, mapper ->
            Map.update(mapper, instruction, [{:always, checker}], fn list ->
              list ++ [{:always, checker}]
            end)
          end)
          |> then(
            &Enum.reduce(checker.when_kept(), &1, fn instruction, mapper ->
              Map.update(mapper, instruction, [{:keep, checker}], fn list ->
                list ++ [{:keep, checker}]
              end)
            end)
          )
      end

    Application.put_env(:clr, :instruction_mapper, instruction_mapper)
  end

  @spec get_checkers() :: [module]
  def get_checkers(), do: Application.get_env(:clr, :checkers, [])

  @spec get_instruction_mapper() :: %{optional(module) => [{:always | :keep, module}]}
  def get_instruction_mapper(), do: Application.get_env(:clr, :instruction_mapper, %{})
end
