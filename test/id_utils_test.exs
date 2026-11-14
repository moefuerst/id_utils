defmodule IDUtilsTest do
  use IDUtils.FixtureCase, async: true

  @fixtures %{
    scheme_cases: ["schemes.jsonc"]
  }

  doctest IDUtils

  describe "detect_schemes/2" do
    test "agrees with fixtures on all valid vectors" do
      for vector <- cases() do
        input = input(vector)
        expected = expected_schemes(vector)

        result = IDUtils.detect_schemes(input)

        assert result == expected
      end
    end
  end

  describe "match?/3" do
    test "agrees with fixtures on all valid vectors" do
      for vector <- cases() do
        scheme = expected_best_match(vector)
        input = input(vector)

        assert IDUtils.match?(input, scheme)
      end
    end
  end

  describe "normalize/3" do
    test "is idempotent" do
      for vector <- cases() do
        scheme = expected_best_match(vector)
        input = input(vector)

        {:ok, normalized} = IDUtils.normalize(input, scheme)
        {:ok, result} = IDUtils.normalize(normalized, scheme)

        assert result == normalized
      end
    end

    test "agrees with fixtures on all valid vectors" do
      for vector <- cases() do
        scheme = expected_best_match(vector)
        input = input(vector)
        expected = Map.fetch!(vector, "canonical")

        {:ok, normalized} = IDUtils.normalize(input, scheme)

        assert normalized == expected
      end
    end
  end

  # Private helpers

  # drops test cases that reference a scheme not available in the catalog
  defp cases do
    available = MapSet.new(IDUtils.Scheme.Catalog.list(), &to_string/1)

    Enum.filter(scheme_cases(), fn %{"matches" => matches} ->
      Enum.all?(matches, &MapSet.member?(available, &1))
    end)
  end

  defp input(vector) do
    Map.fetch!(vector, "input")
  end

  # transforms scheme strings from the fixture into atoms
  defp expected_schemes(vector) do
    vector
    |> Map.fetch!("matches")
    |> Enum.map(&String.to_existing_atom/1)
  end

  defp expected_best_match(vector) do
    vector
    |> Map.fetch!("matches")
    |> Enum.at(0)
    |> String.to_existing_atom()
  end
end
