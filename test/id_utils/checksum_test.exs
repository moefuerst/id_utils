defmodule IDUtils.ChecksumTest do
  use IDUtils.FixtureCase, async: true
  use ExUnitProperties

  alias IDUtils.Checksum

  @fixtures %{
    mod_11_2: ["checksum", "mod_11_2.jsonc"],
    mod_11_weighted: ["checksum", "mod_11_weighted.jsonc"]
  }

  @mod_11_valid_input ?0..?9
  @mod_11_check_char_set_regex ~r/\A[0-9X]\z/

  doctest Checksum

  describe "mod_11_02/1" do
    test "known vectors" do
      assert Checksum.mod_11_2("000000021825009") == "7"
      assert Checksum.mod_11_2("000000029079593") == "X"
    end

    property "returns exactly one char in 0-9 or X" do
      check all(s <- string(@mod_11_valid_input, min_length: 1, max_length: 40)) do
        assert Checksum.mod_11_2(s) =~ @mod_11_check_char_set_regex
      end
    end

    property "input <> check character always validates (full sum ≡ 2 mod 11)" do
      check all(s <- string(@mod_11_valid_input, min_length: 1, max_length: 40)) do
        assert valid_mod_11_2?(s <> Checksum.mod_11_2(s))
      end
    end

    property "prepending zeros does not change the check character" do
      check all(
              s <- string(@mod_11_valid_input, min_length: 1, max_length: 30),
              zeros <- integer(1..5)
            ) do
        assert Checksum.mod_11_2(String.duplicate("0", zeros) <> s) == Checksum.mod_11_2(s)
      end
    end

    test "agrees with fixtures on all vectors" do
      for vector <- mod_11_2() do
        input = Map.fetch!(vector, "input")
        expected = Map.fetch!(vector, "expected")

        assert Checksum.mod_11_2(input) == expected
      end
    end
  end

  describe "mod_11_weighted/1" do
    test "known vectors (ISSN, ISO 3297)" do
      assert Checksum.mod_11_weighted("0306312") == "7"
      assert Checksum.mod_11_weighted("2434561") == "X"
    end

    test "known vectors (ISBN-10, ISO 2108)" do
      assert Checksum.mod_11_weighted("030640615") == "2"
      assert Checksum.mod_11_weighted("080442957") == "X"
    end

    property "returns exactly one char in 0-9 or X" do
      check all(s <- string(@mod_11_valid_input, min_length: 1, max_length: 40)) do
        assert Checksum.mod_11_weighted(s) =~ @mod_11_check_char_set_regex
      end
    end

    property "input <> check character always validates (weighted sum ≡ 0 mod 11)" do
      check all(s <- string(@mod_11_valid_input, min_length: 1, max_length: 40)) do
        assert valid_mod_11_weighted?(s <> Checksum.mod_11_weighted(s))
      end
    end

    property "check character is X exactly when the input's weighted sum ≡ 1 (mod 11)" do
      check all(s <- string(@mod_11_valid_input, min_length: 1, max_length: 40)) do
        # appending "0" (weight 1) leaves the weighted sum unchanged.
        input_sum = weighted_sum(s <> "0")

        check_digit_is_x = Checksum.mod_11_weighted(s) == "X"
        sum_is_congruent_to_one = Integer.mod(input_sum, 11) == 1

        assert check_digit_is_x == sum_is_congruent_to_one
      end
    end

    test "agrees with fixtures on all vectors" do
      for vector <- mod_11_weighted() do
        input = Map.fetch!(vector, "input")
        expected = Map.fetch!(vector, "expected")

        assert Checksum.mod_11_weighted(input) == expected
      end
    end
  end

  # Oracle implementations

  # ISO 7064 MOD 11-2

  defp mod_11_2_sum(binary) do
    char_count = byte_size(binary)

    binary
    |> to_mod_11_values()
    |> Enum.with_index(1)
    |> Enum.map(fn {value, position} ->
      value * Integer.pow(2, char_count - position + 1)
    end)
    |> Enum.sum()
  end

  # check character makes the input sum ≡ 1 mod 11, appending it doubles the sum,
  # so full sum ≡ 2 mod 11
  defp valid_mod_11_2?(full) do
    full
    |> mod_11_2_sum()
    |> Integer.mod(11) == 2
  end

  # Weighted MOD 11 (ISO 3297,ISO 2108, etc.)

  defp weighted_sum(binary) do
    char_count = byte_size(binary)

    binary
    |> to_mod_11_values()
    |> Enum.with_index()
    |> Enum.map(fn {value, position} ->
      value * (char_count - position)
    end)
    |> Enum.sum()
  end

  # weighted check character makes the weighted sum divisible by 11
  defp valid_mod_11_weighted?(full) do
    full
    |> weighted_sum()
    |> Integer.mod(11) == 0
  end

  defp to_mod_11_values(bin) do
    bin
    |> :binary.bin_to_list()
    |> Enum.map(&to_mod_11_value/1)
  end

  defp to_mod_11_value(?X), do: 10
  defp to_mod_11_value(digit) when digit in @mod_11_valid_input, do: digit - ?0
end
