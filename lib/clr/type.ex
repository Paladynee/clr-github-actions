defmodule Clr.Type do
  @type t ::
          ptr_type
          | array_type
          | struct_type
          | scalar_type
          | typeof_type
          | lvalue_type
          | comptime_call_type
          | optional_type

  @type ptr_type :: {:ptr, ptr_count, t, meta}
  @type array_type :: {:array, non_neg_integer, t, meta}
  @type struct_type :: {:struct, [t], meta}
  @type scalar_type :: int_type | uint_type | float_type | special_type
  @type int_type :: {:i, 0..65535, meta}
  @type uint_type :: {:u, 0..65535, meta}
  @type float_type :: {:f, 16 | 32 | 64 | 80 | 128, meta}
  @type special_type :: {:bool | :usize | :void, meta}
  @type typeof_type :: {:TypeOf, term, meta}
  @type lvalue_type :: {:lvalue, term, meta}
  @type comptime_call_type :: {:comptime_call, term, list, meta}
  @type optional_type :: {:optional, t, meta}

  defguard has_refinement(t, key) when (tuple_size(t) == 4 and is_map_key(elem(t, 3), key))
    or (tuple_size(t) == 3 and is_map_key(elem(t, 2), key))
    or (tuple_size(t) == 2 and is_map_key(elem(t, 1), key))

  # TODO: union types

  @type ptr_count :: :one | :many | :slice | :c

  @type slot :: non_neg_integer
  @type meta :: %{optional(atom) => term}

  def valid?(maybe_type) do
    ptr_type?(maybe_type) or
      array_type?(maybe_type) or
      struct_type?(maybe_type) or
      scalar_type?(maybe_type) or
      typeof_type?(maybe_type) or
      lvalue_type?(maybe_type) or
      comptime_call_type?(maybe_type) or
      optional_type?(maybe_type) or
      errorable_type?(maybe_type) or
      void_type?(maybe_type)
  end

  defp ptr_type?(maybe_type) do
    match?({:ptr, count, _type, %{}} when count in ~w[one many slice c]a, maybe_type) and
      valid?(elem(maybe_type, 2))
  end

  defp array_type?(maybe_type) do
    match?({:array, size, _type, %{}} when is_integer(size) and size >= 0, maybe_type) and
      valid?(elem(maybe_type, 2))
  end

  defp struct_type?(maybe_type) do
    match?({:struct, fields, %{}} when is_list(fields), maybe_type) and
      Enum.all?(elem(maybe_type, 1), &valid?/1)
  end

  defp scalar_type?(maybe_type) do
    int_type?(maybe_type) or float_type?(maybe_type) or bool_type?(maybe_type) or
      usize_type?(maybe_type)
  end

  defp int_type?(maybe_type) do
    match?({s, i, %{}} when s in ~w[i u]a and i in 0..65535, maybe_type)
  end

  defp float_type?(maybe_type) do
    match?({:f, s, %{}} when s in [16, 32, 64, 80, 128], maybe_type)
  end

  defp bool_type?(maybe_type), do: match?({:bool, %{}}, maybe_type)
  defp usize_type?(maybe_type), do: match?({:usize, %{}}, maybe_type)
  defp void_type?(maybe_type), do: maybe_type == {:void, %{}}

  defp typeof_type?(maybe_type), do: match?({:TypeOf, _lvalue, %{}}, maybe_type)

  defp lvalue_type?(maybe_type), do: match?({:lvalue, _, %{}}, maybe_type)

  defp comptime_call_type?(maybe_type), do: match?({:comptime_call, _, _, %{}}, maybe_type)

  defp optional_type?(maybe_type) do
    match?({:optional, _, %{}}, maybe_type) and
      valid?(elem(maybe_type, 1))
  end

  defp errorable_type?(maybe_type) do
    match?({:errorable, _, _, %{}}, maybe_type) and
      valid?(elem(maybe_type, 2))
  end

  @spec from_air(term) :: t
  def from_air({:ptr, count, child, meta}), do: {:ptr, count, from_air(child), Map.new(meta)}

  def from_air({:array, count, child, meta}), do: {:array, count, from_air(child), Map.new(meta)}

  def from_air({:struct, fields}), do: {:struct, Enum.map(fields, &from_air/1), %{}}

  def from_air({:lvalue, [one]} = lvalue) do
    case one do
      "usize" -> {:usize, %{}}
      "u" <> int -> make_numbered(:u, int)
      "i" <> int -> make_numbered(:i, int)
      "f" <> int -> make_numbered(:f, int)
      _ -> {lvalue, %{}}
    end
  end

  def from_air({:lvalue, info}), do: {:lvalue, info, %{}}

  def from_air({:comptime_call, call, args}), do: {:comptime_call, call, args, %{}}

  def from_air({:optional, child}), do: {:optional, from_air(child), %{}}

  def from_air({:errorable, errors, child}), do: {:errorable, errors, from_air(child), %{}}

  def void, do: {:void, %{}}

  @spec put_meta(t, meta | keyword) :: t
  @two_tuple ~w[bool usize void]a
  @three_tuple ~w[i u f struct TypeOf lvalue optional]a
  @four_tuple ~w[ptr array comptime_call errorable]a

  def put_meta({two, meta}, more) when two in @two_tuple, do: {two, Enum.into(more, meta)}

  def put_meta({three, a0, meta}, more) when three in @three_tuple,
    do: {three, a0, Enum.into(more, meta)}

  def put_meta({four, a0, a1, meta}, more) when four in @four_tuple,
    do: {four, a0, a1, Enum.into(more, meta)}

  @spec get_meta(t) :: meta
  def get_meta({_, meta}), do: meta
  def get_meta({_, _, meta}), do: meta
  def get_meta({_, _, _, meta}), do: meta

  def make_numbered(class, int) do
    case Integer.parse(int) do
      {num, ""} -> {class, num, %{}}
      _ -> {{:lvalue, "#{class}#{int}"}, %{}}
    end
  end
end
