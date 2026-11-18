defmodule IDUtils.Schemes.GNDTest do
  use IDUtils.FixtureCase, async: true
  use ExUnitProperties

  alias IDUtils.Checksum
  alias IDUtils.Schemes.GND

  @fixtures %{
    sampled_gnds: ["schemes", "gnd_samples.jsonc"]
  }

  # source: https://www.wikidata.org/wiki/Property:P227
  @format ~r"""
    ^(?:
      1[01234]?\d{7}[0-9X]
      | [47]\d{6}-\d
      | [1-9]\d{0,7}-[0-9X]
      | 3\d{7}[0-9X]
    )$
  """x

  @checks ~w(0 1 2 3 4 5 6 7 8 9 X)

  doctest GND

  describe "match?/1" do
    property "rejects wrong check characters" do
      check all(id <- wrong_check()) do
        refute GND.match?(id)
      end
    end

    property "rejects malformed strings" do
      check all(string <- malformed()) do
        refute GND.match?(string)
      end
    end

    test "matches sampled real-world GND ids" do
      failures =
        sampled_gnds()
        |> Enum.map(&input/1)
        |> Enum.reject(&GND.match?/1)

      assert failures == []
    end

    property "matches generated ids" do
      check all(id <- valid(), prefix <- prefix()) do
        assert GND.match?(id)
        assert GND.match?(prefix <> id)
      end
    end

    property "agrees with oracle" do
      check all(id <- valid(), bad_id <- malformed()) do
        assert GND.match?(id) == oracle_match?(id)
        assert GND.match?(bad_id) == oracle_match?(bad_id)
      end
    end
  end

  describe "normalize/1" do
    property "rejects malformed ids" do
      check all(string <- malformed()) do
        assert GND.normalize(string) == {:error, :invalid_identifier}
      end
    end

    test "agrees with sampled real-world ids on canonical form" do
      failures =
        sampled_gnds()
        |> Enum.map(&input/1)
        |> Enum.reject(fn gnd -> match?({:ok, ^gnd}, GND.normalize(gnd)) end)

      assert failures == []
    end

    property "normalizes generated ids" do
      check all(id <- valid(), prefix <- prefix()) do
        assert GND.normalize(id) == {:ok, id}
        assert GND.normalize(prefix <> id) == {:ok, id}
      end
    end
  end

  # Private helpers

  defp valid, do: one_of([legacy(), map(unhyphenated(), &(&1 <> Checksum.mod_11_weighted(&1)))])

  defp prefix, do: member_of(["", "https://d-nb.info/gnd/", "GND: ", "SWD", "(DE-588)"])

  defp wrong_check do
    gen all(id <- valid(), check <- member_of(@checks), check != String.last(id)) do
      String.slice(id, 0..-2//1) <> check
    end
  end

  defp malformed do
    filter(string([?0..?9, ?X, ?-], max_length: 12), &(not Regex.match?(@format, &1)))
  end

  defp legacy do
    map({member_of(?1..?9), digits(0..7)}, fn {first, rest} ->
      payload = <<first>> <> rest
      payload <> "-" <> Checksum.mod_11_weighted_direct(payload)
    end)
  end

  defp unhyphenated do
    one_of([
      map(digits(7), &("1" <> &1)),
      map({member_of(?0..?4), digits(7)}, fn {second, rest} -> <<?1, second>> <> rest end),
      map(digits(7), &("3" <> &1))
    ])
  end

  defp digits(length), do: string(?0..?9, length: length)

  defp input(vector), do: Map.fetch!(vector, "gnd")

  # Oracle implementation

  defp oracle_match?(string) do
    String.match?(string, @format)
  end
end
