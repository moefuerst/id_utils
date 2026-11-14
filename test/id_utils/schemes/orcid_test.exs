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
  end
end
