defmodule IDUtils.ChecksumTest do
  use IDUtils.FixtureCase, async: true
  use ExUnitProperties

  alias IDUtils.Checksum

  @fixtures %{
    mod_11_2: ["checksum", "mod_11_2.jsonc"],
    mod_11_weighted: ["checksum", "mod_11_weighted.jsonc"],
    mod_97_10: ["checksum", "mod_97_10.jsonc"],
    ncda: ["checksum", "ncda.jsonc"]
  }

  @decimal_digits ?0..?9
  @betanumeric "0123456789bcdfghjkmnpqrstvwxz"

  doctest Checksum

  describe "mod_11_02/1" do
    test "known vectors (ORCID)" do
      assert Checksum.mod_11_2("000000021825009") == "7"
      assert Checksum.mod_11_2("000000029079593") == "X"
    end

    property "input <> check character always validates (full sum ≡ 2 mod 11)" do
      check all(s <- string(@decimal_digits, min_length: 1, max_length: 40)) do
        assert valid_mod_11_2?(s <> Checksum.mod_11_2(s))
      end
    end

    property "prepending zeros does not change the check character" do
      check all(
              s <- string(@decimal_digits, min_length: 1, max_length: 30),
              zeros <- integer(1..5)
            ) do
        assert Checksum.mod_11_2(String.duplicate("0", zeros) <> s) == Checksum.mod_11_2(s)
      end
    end

    property "any non-digit byte anywhere raises" do
      check all(input <- invalid_input()) do
        assert_raise FunctionClauseError, fn -> Checksum.mod_11_2(input) end
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

    property "input <> check character always validates (weighted sum ≡ 0 mod 11)" do
      check all(s <- string(@decimal_digits, min_length: 1, max_length: 40)) do
        assert valid_mod_11_weighted?(s <> Checksum.mod_11_weighted(s))
      end
    end

    property "check character is X exactly when the input's weighted sum ≡ 1 (mod 11)" do
      check all(s <- string(@decimal_digits, min_length: 1, max_length: 40)) do
        # appending "0" (weight 1) leaves the weighted sum unchanged.
        input_sum = weighted_sum(s <> "0")

        check_digit_is_x = Checksum.mod_11_weighted(s) == "X"
        sum_is_congruent_to_one = Integer.mod(input_sum, 11) == 1

        assert check_digit_is_x == sum_is_congruent_to_one
      end
    end

    property "any non-digit byte anywhere raises" do
      check all(input <- invalid_input()) do
        assert_raise FunctionClauseError, fn -> Checksum.mod_11_weighted(input) end
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

  describe "mod_11_weighted_direct/1" do
    test "known vectors (GND)" do
      assert Checksum.mod_11_weighted_direct("4021455") == "2"
      assert Checksum.mod_11_weighted_direct("4079878") == "1"
      assert Checksum.mod_11_weighted_direct("2054656") == "7"
      assert Checksum.mod_11_weighted_direct("212535") == "3"
      assert Checksum.mod_11_weighted_direct("3070187") == "9"
    end

    property "any non-digit byte anywhere raises" do
      check all(input <- invalid_input()) do
        assert_raise FunctionClauseError, fn -> Checksum.mod_11_weighted_direct(input) end
      end
    end
  end

  describe "mod_97_10/1" do
    property "input <> check digit pair always validates (full number ≡ 1 mod 97)" do
      check all(s <- string(@decimal_digits, min_length: 1, max_length: 40)) do
        assert valid_mod_97_10?(s <> Checksum.mod_97_10(s))
      end
    end

    property "prepending zeros does not change the check digit pair" do
      check all(
              s <- string(@decimal_digits, min_length: 1, max_length: 30),
              zeros <- integer(1..5)
            ) do
        assert Checksum.mod_97_10(String.duplicate("0", zeros) <> s) == Checksum.mod_97_10(s)
      end
    end

    property "check digit pair is exactly two decimal digits with a value in 02..98" do
      check all(s <- string(@decimal_digits, min_length: 1, max_length: 40)) do
        pair = Checksum.mod_97_10(s)

        assert pair =~ ~r/\A\d{2}\z/
        assert String.to_integer(pair) in 2..98
      end
    end

    property "any non-digit byte anywhere raises" do
      check all(input <- invalid_input()) do
        assert_raise FunctionClauseError, fn -> Checksum.mod_97_10(input) end
      end
    end

    test "agrees with fixtures on all vectors" do
      for vector <- mod_97_10() do
        input = Map.fetch!(vector, "input")
        expected = Map.fetch!(vector, "expected")

        assert Checksum.mod_97_10(input) == expected
      end
    end
  end

  describe "ncda/1" do
    property "check character's ordinal ≡ position-weighted sum (mod 29)" do
      check all(s <- binary(max_length: 80)) do
        assert valid_ncda?(s, Checksum.ncda(s))
      end
    end

    test "empty is a valid NCDA checksum" do
      assert Checksum.ncda("") == "0"
    end

    test "agrees with fixtures on all vectors" do
      for %{"input" => input, "expected" => expected} <- ncda() do
        assert Checksum.ncda(input) == expected
      end
    end
  end

  # Private helpers

  defp invalid_input do
    one_of([
      input_with_non_digit_byte(),
      member_of(["", "１２３", "١٢٣", nil, 123, ~c"123", <<1::3>>])
    ])
  end

  # valid digit string with exactly one non-digit byte inserted at a random position
  defp input_with_non_digit_byte do
    gen all(
          s <- string(@decimal_digits, min_length: 0, max_length: 20),
          bad <- member_of(Enum.to_list(0..255) -- Enum.to_list(@decimal_digits)),
          pos <- integer(0..byte_size(s))
        ) do
      <<pre::binary-size(^pos), post::binary>> = s

      pre <> <<bad>> <> post
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
  defp to_mod_11_value(digit) when digit in @decimal_digits, do: digit - ?0

  # ISO 7064 MOD 97-10

  defp valid_mod_97_10?(full) do
    full
    |> String.to_integer()
    |> Integer.mod(97) == 1
  end

  # NCDA

  defp ncda_sum(binary) do
    binary
    |> :binary.bin_to_list()
    |> Enum.with_index(1)
    |> Enum.map(fn {byte, position} ->
      to_ncda_value(byte) * position
    end)
    |> Enum.sum()
  end

  # check character's ordinal is the payload's weighted sum mod 29
  defp valid_ncda?(payload, <<check>>) do
    payload
    |> ncda_sum()
    |> Integer.mod(29) == to_ncda_value(check)
  end

  defp to_ncda_value(byte) do
    case :binary.match(@betanumeric, <<byte>>) do
      {ordinal, 1} -> ordinal
      :nomatch -> 0
    end
  end
end
