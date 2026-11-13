defmodule IDUtils.Schemes.RAIDTest do
  use IDUtils.FixtureCase, async: true

  alias IDUtils.Schemes.DOI
  alias IDUtils.Schemes.RAID

  # RAID and a DOI are format-identical, these tests verify just that.
  #
  # The current implementation delegates to the DOI module after stripping the prefix, so see
  # DOITest for more details.

  @fixtures %{
    sampled_dois: ["schemes", "doi_samples.jsonc"]
  }

  doctest RAID

  describe "match?/1" do
    test "matches a RAID when prefixed" do
      raid = "10.5281/zenodo.15293455"
      # sanity check
      assert RAID.match?(raid)

      assert RAID.match?("https://raid.org/" <> raid)
    end

    test "agrees with DOI.match?/1 on sampled identifiers" do
      failures =
        sampled_dois()
        |> Enum.map(&input/1)
        |> Enum.reject(fn raid -> RAID.match?(raid) and DOI.match?(raid) end)

      assert failures == []
    end
  end

  describe "normalize/1" do
    test "agrees with DOI.normalize/1 on canonical form" do
      failures =
        sampled_dois()
        |> Enum.map(&input/1)
        |> Enum.reject(fn raid ->
          match?({:ok, ^raid}, RAID.normalize(raid)) and
            match?({:ok, ^raid}, DOI.normalize(raid))
        end)

      assert failures == []
    end
  end

  # Private helpers

  defp input(vector), do: Map.fetch!(vector, "doi")
end
