defmodule IDUtils.Schemes.ISNITest do
  use IDUtils.FixtureCase, async: true

  alias IDUtils.Schemes.ISNI

  @fixtures %{
    sampled_isnis: ["schemes", "isni_samples.jsonc"]
  }

  doctest ISNI

  describe "match?/1" do
    test "verifies checksum" do
      base = "000000012146438"

      assert ISNI.match?(base <> "X") == true
      refute ISNI.match?(base <> "0")
    end

    test "accepts ISNIs with space or hyphen separators" do
      space_separated = "0000 0001 2146 438X"
      hypen_separated = "0000-0001-2146-438X"

      assert ISNI.match?(space_separated)
      assert ISNI.match?(hypen_separated)
    end

    test "rejects malformed digit sequences" do
      for identifier <- [
            "",
            "-0000-0001-2146-438X-",
            "00000002182500977",
            "0000\t0002\t1825\t0097",
            "0000-0002-1825-0097\n"
          ] do
        refute ISNI.match?(identifier)
      end
    end

    test "matches sampled real-world ISNIs" do
      failures =
        sampled_isnis()
        |> Enum.map(&input/1)
        |> Enum.reject(&ISNI.match?/1)

      assert failures == []
    end

    test "also matches an ORCID unless it has a dedicated prefix" do
      identifier = "0000-0002-1825-0097"

      assert ISNI.match?(identifier)
      refute ISNI.match?("https://orcid.org/" <> identifier)
      refute ISNI.match?("http://orcid.org/" <> identifier)
    end
  end

  describe "normalize/1" do
    test "strips prefixes and returns the canonical ISNI" do
      result = ISNI.normalize("https://isni.org/isni/000000012146438X")

      assert result == {:ok, "000000012146438X"}
    end

    test "does not imply a valid checksum" do
      identifier = "0000000121464380"

      assert ISNI.normalize(identifier) == {:ok, identifier}
      refute ISNI.match?(identifier)
    end

    test "is idempotent" do
      for vector <- sampled_isnis() do
        input = input(vector)

        {:ok, normalized} = ISNI.normalize(input)
        {:ok, result} = ISNI.normalize(normalized)

        assert result == normalized
      end
    end

    test "is invariant under changes in representation" do
      for vector <- sampled_isnis() do
        input = input(vector)

        assert expected = ISNI.normalize(input)

        assert ISNI.normalize("https://isni.org/isni/" <> input) == expected
        assert ISNI.normalize("https://isni.org/" <> input) == expected
        assert ISNI.normalize("isni:" <> input) == expected
        assert ISNI.normalize("ISNI " <> input) == expected
        assert ISNI.normalize("(isni)" <> input) == expected
      end
    end

    test "discards separators between groups of four digits" do
      identifier = "0000-0001 2146-438X"
      expected = "000000012146438X"

      {:ok, result} = ISNI.normalize(identifier)

      assert result == expected
    end
  end

  describe "prefix?/1" do
    test "returns true if the given string starts with an ISNI prefix" do
      for string <- [
            "https://isni.org/isni/1234",
            "https://isni.org/1234",
            "http://www.isni.org/isni/1234",
            "http://isni.org/isni/1234",
            "isni.org/isni/1234",
            "isni.org/1234",
            "isni:1234",
            "ISNI|1234",
            "ISNI 1234",
            "(isni)1234"
          ] do
        assert ISNI.prefix?(string)
      end
    end

    test "returns false for a given string without ISNI prefix" do
      refute ISNI.prefix?("000000012146438X")
    end

    test "returns false for a given string with an unknown ISNI prefix" do
      refute ISNI.prefix?("[ISNI] 000000012146438X")
    end
  end

  # Private helpers

  defp input(vector), do: Map.fetch!(vector, "isni")
end
