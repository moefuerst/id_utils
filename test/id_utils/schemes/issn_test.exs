defmodule IDUtils.Schemes.ISSNTest do
  use ExUnit.Case, async: true

  alias IDUtils.Schemes.ISSN

  doctest ISSN

  describe "match?/1" do
    test "verifies checksum" do
      base = "0306312"

      assert ISSN.match?(base <> "7") == true
      refute ISSN.match?(base <> "X")
    end

    test "accepts ISSNs with space or hyphen separators" do
      space_separated = "2049 3630"
      hypen_separated = "2049-3630"

      assert ISSN.match?(space_separated)
      assert ISSN.match?(hypen_separated)
    end

    test "rejects malformed digit sequences" do
      for identifier <- [
            "",
            "-2049-3630-",
            "2049\t3630",
            "2049-3630\n"
          ] do
        refute ISSN.match?(identifier)
      end
    end
  end

  describe "normalize/1" do
    test "does not imply a valid checksum" do
      identifier = "1234-567X"

      assert ISSN.normalize(identifier) == {:ok, identifier}
      refute ISSN.match?(identifier)
    end
  end
end
