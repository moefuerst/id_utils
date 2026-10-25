defmodule IDUtils.Schemes.ISSNTest do
  use ExUnit.Case, async: true

  alias IDUtils.Schemes.ISSN

  doctest ISSN

  describe "normalize/1" do
    test "normalization does not imply a valid checksum" do
      identifier = "1234-567X"

      assert ISSN.normalize(identifier) == {:ok, identifier}
      refute ISSN.match?(identifier)
    end
  end
end
