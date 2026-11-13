defmodule IDUtils.Schemes.ORCIDTest do
  use ExUnit.Case, async: true

  alias IDUtils.Schemes.ORCID

  doctest ORCID

  describe "match?/1" do
    test "validates the inclusive endpoints of both allocated ISNI blocks" do
      for {number, expected} <- [
            {14_999_999, false},
            {15_000_000, true},
            {35_000_000, true},
            {35_000_001, false},
            {899_999_999_999, false},
            {900_000_000_000, true},
            {900_100_000_000, true},
            {900_100_000_001, false}
          ] do
        identifier =
          number
          |> Integer.to_string()
          |> String.pad_leading(15, "0")
          |> then(&Kernel.<>(&1, IDUtils.Checksum.mod_11_2(&1)))

        assert ORCID.match?(identifier) == expected
      end
    end
  end

  describe "normalize/1" do
    test "strips prefixes and returns the canonical ORCID" do
      result = ORCID.normalize("https://orcid.org/0000-0002-1825-0097")

      assert result == {:ok, "0000-0002-1825-0097"}
    end

    test "does not imply a valid checksum or allocated block" do
      for identifier <- ["0000-0002-1825-0098", "0008-9999-9999-9996"] do
        assert ORCID.normalize(identifier) == {:ok, identifier}
        refute ORCID.match?(identifier)
      end
    end

    test "rejects malformed digit sequences" do
      for identifier <- [
            "",
            "000000021825009",
            "00000002182500977",
            "0000-000X-1825-0097",
            "0000-0002-1825-009A",
            "0000\t0002\t1825\t0097",
            "0000-0002-1825-0097\n",
            "-0000-0002-1825-0097-"
          ] do
        assert ORCID.normalize(identifier) == {:error, :invalid_identifier}
      end
    end

    test "accepts X only as the sixteenth non-separator byte" do
      for invalid_identifier <- [
            "00000002169423x3",
            "000000021694233xx",
            "000000021694233x0",
            "00000002169423x",
            "000000021694233x\t",
            <<"000000021694233", 255>>
          ] do
        assert ORCID.normalize(invalid_identifier) == {:error, :invalid_identifier}
      end
    end
  end
end
