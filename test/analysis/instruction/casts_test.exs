defmodule ClrTest.Analysis.Instruction.CastsTest do
  use ExUnit.Case, async: true

  alias Clr.Air.Instruction
  alias Clr.Air.Function
  alias Clr.Block

  import Clr.Air.Lvalue

  setup do
    block =
      %Function{name: ~l"foo.bar"}
      |> Block.new([], :void)
      |> Map.put(:loc, {47, 47})

    {:ok, block: block, config: %Instruction{}}
  end

  describe "bitcast" do
    alias Clr.Air.Instruction.Casts.Bitcast

    test "makes default type when it's not a slotref", %{block: block} do
      assert {{:ptr, :one, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %Bitcast{type: {:ptr, :one, ~l"u8", []}, src: ~l"some.constant"},
                 0,
                 block
               )
    end

    test "transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:usize, %{foo: :bar}})

      assert {{:ptr, :one, {:u, 8, %{}}, %{foo: :bar}}, _} =
               Instruction.slot_type(
                 %Bitcast{type: {:ptr, :one, ~l"u8", []}, src: {0, :keep}},
                 0,
                 block
               )
    end
  end

  describe "int_from_ptr" do
    alias Clr.Air.Instruction.Casts.IntFromPtr

    test "makes default type when it's not a slotref", %{block: block} do
      assert {{:usize, %{}}, _} =
               Instruction.slot_type(%IntFromPtr{src: ~l"some.constant"}, 0, block)
    end

    test "transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:usize, %{foo: :bar}})

      assert {{:usize, %{foo: :bar}}, _} =
               Instruction.slot_type(%IntFromPtr{src: {0, :keep}}, 0, block)
    end
  end

  describe "int_from_bool" do
    alias Clr.Air.Instruction.Casts.IntFromBool

    test "makes default type when it's not a slotref", %{block: block} do
      assert {{:u, 1, %{}}, _} =
               Instruction.slot_type(%IntFromBool{src: ~l"some.constant"}, 0, block)
    end

    test "transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:i, 1, %{foo: :bar}})

      assert {{:u, 1, %{foo: :bar}}, _} =
               Instruction.slot_type(%IntFromBool{src: {0, :keep}}, 0, block)
    end
  end

  describe "intcast" do
    alias Clr.Air.Instruction.Casts.Intcast

    test "makes default type when it's not a slotref", %{block: block} do
      assert {{:i, 8, %{}}, _} =
               Instruction.slot_type(%Intcast{type: ~l"i8", src: ~l"some.constant"}, 0, block)
    end

    test "transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:i, 8, %{foo: :bar}})

      assert {{:i, 8, %{foo: :bar}}, _} =
               Instruction.slot_type(%Intcast{type: ~l"i8", src: {0, :keep}}, 0, block)
    end
  end

  describe "trunc" do
    alias Clr.Air.Instruction.Casts.Trunc

    test "makes default type when it's not a slotref", %{block: block} do
      assert {{:i, 8, %{}}, _} =
               Instruction.slot_type(%Trunc{type: ~l"i8", src: ~l"some.constant"}, 0, block)
    end

    test "transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:i, 8, %{foo: :bar}})

      assert {{:i, 8, %{foo: :bar}}, _} =
               Instruction.slot_type(%Trunc{type: ~l"i8", src: {0, :keep}}, 0, block)
    end
  end

  describe "optional_payload" do
    alias Clr.Air.Instruction.Casts.OptionalPayload

    test "unwraps slot information, merging from optionals", %{block: block} do
      block =
        Block.put_type(
          block,
          0,
          {:optional, {:u, 8, %{foo: :bar}}, %{bar: :baz}}
        )

      assert {{:u, 8, %{foo: :bar, bar: :baz}}, _} =
               Instruction.slot_type(
                 %OptionalPayload{type: ~l"u8", src: {0, :keep}},
                 0,
                 block
               )
    end

    test "creates when there is no slot information", %{block: block} do
      assert {{:u, 8, %{}}, _} =
               Instruction.slot_type(
                 %OptionalPayload{type: ~l"u8", src: ~l"some.constant"},
                 0,
                 block
               )
    end
  end

  describe "optional_payload_ptr" do
    alias Clr.Air.Instruction.Casts.OptionalPayloadPtr

    test "unwraps slot information, merging from optionals", %{block: block} do
      block =
        Block.put_type(
          block,
          0,
          {:ptr, :one, {:optional, {:u, 8, %{foo: :bar}}, %{bar: :baz}}, %{quux: :mlem}}
        )

      assert {{:ptr, :one, {:u, 8, %{foo: :bar, bar: :baz}}, %{quux: :mlem}}, _} =
               Instruction.slot_type(
                 %OptionalPayloadPtr{type: {:ptr, :one, ~l"u8", []}, src: {0, :keep}},
                 0,
                 block
               )
    end

    test "creates when there is no slot information", %{block: block} do
      assert {{:ptr, :one, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %OptionalPayloadPtr{type: {:ptr, :one, ~l"u8", []}, src: ~l"some.constant"},
                 0,
                 block
               )
    end
  end

  describe "wrap_optional" do
    alias Clr.Air.Instruction.Casts.WrapOptional

    test "wraps the child when it's a slot", %{block: block} do
      block = Block.put_type(block, 0, {:u, 8, %{}}, foo: :bar)

      assert {{:optional, {:u, 8, %{foo: :bar}}, %{}}, _} =
               Instruction.slot_type(
                 %WrapOptional{type: {:optional, ~l"u8"}, src: {0, :keep}},
                 0,
                 block
               )
    end

    test "generates new data when it's not a slot", %{block: block} do
      assert {{:optional, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %WrapOptional{type: {:optional, ~l"u8"}, src: ~l"some.constant"},
                 0,
                 block
               )
    end
  end

  describe "unwrap_errunion_payload" do
    alias Clr.Air.Instruction.Casts.UnwrapErrunionPayload

    test "unwraps the child when it's a slot", %{block: block} do
      block =
        Block.put_type(
          block,
          0,
          {:errorunion, [~l"foo"], {:u, 8, %{foo: :bar}}, %{}}
        )

      assert {{:u, 8, %{foo: :bar}}, _} =
               Instruction.slot_type(
                 %UnwrapErrunionPayload{type: ~l"u8", src: {0, :keep}},
                 0,
                 block
               )
    end

    test "generates new data when it's not a slot", %{block: block} do
      assert {{:u, 8, %{}}, _} =
               Instruction.slot_type(
                 %UnwrapErrunionPayload{type: ~l"u8", src: ~l"some.constant"},
                 0,
                 block
               )
    end
  end

  alias Clr.Air.Instruction.Casts.UnwrapErrunionErr

  test "unwrap_errunion_err", %{block: block} do
    assert {{:errorset, [~l"foo"], _}, _} =
             Instruction.slot_type(
               %UnwrapErrunionErr{type: {:errorset, [~l"foo"]}, src: {0, :keep}},
               0,
               block
             )
  end

  describe "unwrap_errunion_payload_ptr" do
    alias Clr.Air.Instruction.Casts.UnwrapErrunionPayloadPtr

    test "unwraps the child when it's a slot", %{block: block} do
      block =
        Block.put_type(
          block,
          0,
          {:ptr, :one, {:errorunion, [~l"foo"], {:u, 8, %{foo: :bar}}, %{}}, %{}}
        )

      assert {{:ptr, :one, {:u, 8, %{foo: :bar}}, %{}}, _} =
               Instruction.slot_type(
                 %UnwrapErrunionPayloadPtr{type: {:ptr, :one, ~l"u8", []}, src: {0, :keep}},
                 0,
                 block
               )
    end

    test "generates new data when it's not a slot", %{block: block} do
      assert {{:ptr, :one, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %UnwrapErrunionPayloadPtr{
                   type: {:ptr, :one, ~l"u8", []},
                   src: ~l"some.constant"
                 },
                 0,
                 block
               )
    end
  end

  alias Clr.Air.Instruction.Casts.UnwrapErrunionErrPtr

  test "unwaps error", %{block: block} do
    assert {{:errorset, [~l"foo"], %{}}, _} =
             Instruction.slot_type(
               %UnwrapErrunionErrPtr{
                 type: {:errorset, [~l"foo"]},
                 src: {0, :keep}
               },
               0,
               block
             )
  end

  describe "errunion_payload_ptr_set" do
    alias Clr.Air.Instruction.Casts.ErrunionPayloadPtrSet

    test "unwraps the child when it's a slot", %{block: block} do
      block =
        Block.put_type(
          block,
          0,
          {:ptr, :one, {:errorunion, [~l"foo"], {:u, 8, %{foo: :bar}}, %{}}, %{}}
        )

      assert {{:ptr, :one, {:u, 8, %{foo: :bar}}, %{}}, _} =
               Instruction.slot_type(
                 %ErrunionPayloadPtrSet{type: {:ptr, :one, ~l"u8", []}, src: {0, :keep}},
                 0,
                 block
               )
    end

    test "generates new data when it's not a slot", %{block: block} do
      assert {{:ptr, :one, {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %ErrunionPayloadPtrSet{type: {:ptr, :one, ~l"u8", []}, src: ~l"some.constant"},
                 0,
                 block
               )
    end
  end

  describe "wrap_errunion_payload" do
    alias Clr.Air.Instruction.Casts.WrapErrunionPayload

    test "makes default type when it's not a slotref", %{block: block} do
      assert {{:errorunion, [~l"OutOfMemory"], {:u, 8, %{}}, %{}}, _} =
               Instruction.slot_type(
                 %WrapErrunionPayload{
                   type: {:errorunion, [~l"OutOfMemory"], ~l"u8"},
                   src: ~l"some.constant"
                 },
                 0,
                 block
               )
    end

    test "correctly transfers child metadata", %{block: block} do
      block = Block.put_type(block, 0, {:u, 8, %{}}, foo: :bar)

      assert {{:errorunion, [~l"OutOfMemory"], {:u, 8, %{foo: :bar}}, %{}}, _} =
               Instruction.slot_type(
                 %WrapErrunionPayload{
                   type: {:errorunion, [~l"OutOfMemory"], ~l"u8"},
                   src: {0, :keep}
                 },
                 0,
                 block
               )
    end
  end

  alias Clr.Air.Instruction.Casts.WrapErrunionErr

  test "wrap_errunion_err", %{block: block} do
    assert {{:errorunion, [~l"OutOfMemory"], :void, %{}}, _} =
             Instruction.slot_type(
               %WrapErrunionErr{type: {:errorunion, [~l"OutOfMemory"], :void}, src: {0, :keep}},
               0,
               block
             )
  end

  describe "int_from_float" do
    alias Clr.Air.Instruction.Casts.IntFromFloat

    test "makes default type when it's not a slotref", %{block: block} do
      assert {{:i, 32, %{}}, _} =
               Instruction.slot_type(
                 %IntFromFloat{type: ~l"i32", src: ~l"some.constant"},
                 0,
                 block
               )
    end

    test "transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:f, 32, %{foo: :bar}})

      assert {{:i, 32, %{foo: :bar}}, _} =
               Instruction.slot_type(%IntFromFloat{type: ~l"i32", src: {0, :keep}}, 0, block)
    end
  end

  describe "float_from_int" do
    alias Clr.Air.Instruction.Casts.FloatFromInt

    test "correctly makes the type when it's not a slotref", %{block: block} do
      assert {{:f, 32, %{}}, _} =
               Instruction.slot_type(
                 %FloatFromInt{type: ~l"f32", src: ~l"some.constant"},
                 0,
                 block
               )
    end

    test "correctly transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:i, 32, %{foo: :bar}})

      assert {{:f, 32, %{foo: :bar}}, _} =
               Instruction.slot_type(%FloatFromInt{type: ~l"f32", src: {0, :keep}}, 0, block)
    end
  end

  describe "fpext" do
    alias Clr.Air.Instruction.Casts.Fpext

    test "correctly makes the type when it's not a slotref", %{block: block} do
      assert {{:f, 64, %{}}, _} =
               Instruction.slot_type(%Fpext{type: ~l"f64", src: ~l"some.constant"}, 0, block)
    end

    test "correctly transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:f, 32, %{foo: :bar}})

      assert {{:f, 64, %{foo: :bar}}, _} =
               Instruction.slot_type(%Fpext{type: ~l"f64", src: {0, :keep}}, 0, block)
    end
  end

  describe "fptrunc" do
    alias Clr.Air.Instruction.Casts.Fptrunc

    test "correctly makes the type when it's not a slotref", %{block: block} do
      assert {{:f, 16, %{}}, _} =
               Instruction.slot_type(%Fptrunc{type: ~l"f16", src: ~l"some.constant"}, 0, block)
    end

    test "correctly transfers type metadata", %{block: block} do
      block = Block.put_type(block, 0, {:f, 16, %{foo: :bar}})

      assert {{:f, 16, %{foo: :bar}}, _} =
               Instruction.slot_type(%Fptrunc{type: ~l"f16", src: {0, :keep}}, 0, block)
    end
  end
end
