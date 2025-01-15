defmodule Clr do
  alias Clr.Lvalue

  @type type :: ptr_type | array_type | struct_type | scalar_type | typeof_type

  @type ptr_type :: {:ptr, ptr_count, type, meta}
  @type array_type :: {:array, non_neg_integer, type, meta}
  @type struct_type :: {:struct, [type], meta}
  @type scalar_type :: int_type | uint_type | float_type | bool_type
  @type int_type :: {:i, 0..65535, meta}
  @type uint_type :: {:u, 0..65535, meta}
  @type float_type :: {:f, 16 | 32 | 64 | 80 | 128, meta}
  @type bool_type :: {:bool, meta}
  @type typeof_type :: {:TypeOf, Lvalue.t(), meta}

  # TODO: union types

  @type ptr_count :: :one | :many | :slice | :c

  @type slot :: non_neg_integer
  @type meta :: %{optional(atom) => term}

  def type?(type) do
    ptr_type?(type) or
      array_type?(type) or
      struct_type?(type) or
      scalar_type?(type) or
      typeof_type?(type)
  end

  defp ptr_type?(type) do
    match?({:ptr, count, _type, %{}} when count in ~w[one many slice c]a, type) and
      type?(elem(type, 2))
  end

  defp array_type?(type) do
    match?({:array, size, _type, %{}} when is_integer(size) and size >= 0, type) and
      type?(elem(type, 2))
  end

  defp struct_type?(type) do
    match?({:struct, fields, %{}} when is_list(fields), type) and
      Enum.all?(elem(type, 1), &type?/1)
  end

  defp scalar_type?(type) do
    int_type?(type) or float_type?(type) or bool_type?(type)
  end

  defp int_type?(type) do
    match?({s, i, %{}} when s in ~w[i u] and i in 0..65535, type)
  end

  defp float_type?(type) do
    match?({:f, s, %{}} when s in [16, 32, 64, 80, 128], type)
  end

  defp bool_type?(type), do: match?({:bool, %{}}, type)

  defp typeof_type?(type), do: match?({:TypeOf, _lvalue, %{}}, type)

  def debug_prefix, do: Application.get_env(:clr, :debug_prefix)
end
