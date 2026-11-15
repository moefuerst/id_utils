defmodule IDUtils.Schemes.RORTest do
  use IDUtils.FixtureCase, async: true

  alias IDUtils.Schemes.ROR

  @fixtures %{
    sampled_rors: ["schemes", "ror_samples.jsonc"]
  }

  doctest ROR

  describe "match?/1" do
    test "matches sampled real-world ROR IDs" do
      failures =
        sampled_rors()
        |> Enum.map(&input/1)
        |> Enum.reject(&ROR.match?/1)

      assert failures == []
    end
  end

  describe "normalize/1" do
    test "agrees with sampled real-world ROR IDs on canonical form" do
      failures =
        sampled_rors()
        |> Enum.map(&input/1)
        |> Enum.reject(fn ror -> match?({:ok, ^ror}, ROR.normalize(ror)) end)

      assert failures == []
    end
  end

  # Private helpers

  defp input(vector), do: Map.fetch!(vector, "ror")
end
