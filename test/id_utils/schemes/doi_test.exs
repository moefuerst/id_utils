defmodule IDUtils.Schemes.DOITest do
  use IDUtils.FixtureCase, async: true
  use ExUnitProperties

  alias IDUtils.Schemes.DOI

  @fixtures %{
    sampled_dois: ["schemes", "doi_samples.jsonc"]
  }

  doctest DOI

  describe "match?/1" do
    test "matches a string that conforms to the scheme" do
      identifier = "10.1000/1234"

      assert DOI.match?(identifier) == true
    end

    test "rejects an empty suffix" do
      identifier = "10.1000/"

      refute DOI.match?(identifier)
    end

    test "rejects a missing slash" do
      identifier = "10.10001234"

      refute DOI.match?(identifier)
    end

    test "rejects a prefix without the DOI namespace" do
      # prefix without "10." is currently not matched as a DOI. see module docs.
      identifier = "15434/1234"

      refute DOI.match?(identifier)
    end

    test "matches registrant code with subdivisions" do
      for identifier <- [
            "10.1000.01/1234",
            "10.1000.01.01/1234",
            "10.12.00.01.01/1234"
          ] do
        assert DOI.match?(identifier)
      end
    end

    test "rejects a missing registrant code" do
      for identifier <- ["10/1234", "10./1234"] do
        refute DOI.match?(identifier)
      end
    end

    test "rejects registrant code ending in a dot" do
      identifier = "10.1000./1234"

      refute DOI.match?(identifier)
    end

    test "rejects consecutive dots in the registrant code" do
      for identifier <- [
            "10.1000..10/1234",
            "10.1000..0010/1234",
            "10.1000.00..10/1234"
          ] do
        refute DOI.match?(identifier)
      end
    end

    test "rejects chars that are not number or dot in the registrant code" do
      for identifier <- [
            "10.absd/1234",
            "10.ab.sd/1234",
            "10.1000a/1234"
          ] do
        refute DOI.match?(identifier)
      end
    end

    test "rejects whitespace" do
      for identifier <- [
            " 10.1000/1234",
            "10.1000/1234 ",
            "10 .1000/1234",
            "10. 1000/1234",
            "10.10 00/1234",
            "10.1000/12 34",
            "10.1000 /1234",
            "10.1000/ 1234",
            "10.1000. 01/1234"
          ] do
        refute DOI.match?(identifier)
      end
    end

    test "rejects a trailing newline" do
      identifier = "10.1000/1234\n"

      refute DOI.match?(identifier)
    end

    test "matches sampled real-world DOIs" do
      failures =
        sampled_dois()
        |> Enum.map(&input/1)
        |> Enum.reject(&DOI.match?/1)

      assert failures == []
    end

    property "matches generated DOIs" do
      check all(input <- valid_doi([:representation, :permissive])) do
        assert DOI.match?(input)
      end
    end
  end

  describe "normalize/1" do
    test "strips prefixes and returns the canonical DOI" do
      result = DOI.normalize("https://doi.org/10.1000/ABC")

      assert result == {:ok, "10.1000/abc"}
    end

    property "produces a result that match?/1 matches as a DOI" do
      check all(input <- valid_doi([:representation, :permissive])) do
        # sanity check
        assert DOI.match?(input)

        assert {:ok, normalized} = DOI.normalize(input)
        assert DOI.match?(normalized)
      end
    end

    property "is idempotent" do
      check all(input <- valid_doi([:representation, :permissive])) do
        {:ok, normalized} = DOI.normalize(input)
        {:ok, result} = DOI.normalize(normalized)

        assert result == normalized
      end
    end

    property "is invariant under changes in representation" do
      check all(input <- one_of([string(:printable), valid_doi()])) do
        expected = DOI.normalize(input)

        assert DOI.normalize("doi: " <> input) == expected
        assert DOI.normalize("https://doi.org/" <> input) == expected
        assert DOI.normalize("http://dx.doi.org/" <> input) == expected
        assert DOI.normalize("doi.org/" <> input) == expected
        assert DOI.normalize("info:doi/" <> input) == expected
        assert DOI.normalize("urn:doi:" <> input) == expected
      end
    end

    test "agrees with sampled real-world DOIs on canonical form" do
      failures =
        sampled_dois()
        |> Enum.map(&input/1)
        |> Enum.reject(fn doi -> match?({:ok, ^doi}, DOI.normalize(doi)) end)

      assert failures == []
    end
  end

  # Private helpers

  defp valid_doi(opts \\ []) do
    representation =
      if Keyword.get(opts, :permissive) do
        member_of([
          "",
          "https://doi.org/",
          "doi:",
          "http://dx.doi.org/",
          "doi.org/",
          "info:doi/",
          "urn:doi:"
        ])
      else
        constant("")
      end

    suffix =
      if Keyword.get(opts, :permissive) do
        permissive_suffix()
      else
        practical_suffix()
      end

    gen all(r <- representation, p <- prefix(), s <- suffix) do
      r <> p <> "/" <> s
    end
  end

  defp prefix do
    gen all(reg <- registrant()) do
      "10." <> reg
    end
  end

  defp registrant do
    code = string([?0..?9], min_length: 4, max_length: 15)
    subdivision = string([?0..?9], min_length: 1, max_length: 4)

    gen all(
          main <- code,
          subs <- one_of([constant([]), list_of(subdivision, min_length: 1, max_length: 5)])
        ) do
      Enum.join([main | subs], ".")
    end
  end

  # conservative suffix: what most registrars issue currently
  defp practical_suffix do
    string(
      [?a..?z, ?A..?Z, ?0..?9, ?-, ?., ?_, ?;, ?(, ?), ?/, ?:],
      min_length: 1,
      max_length: 80
    )
  end

  # doi handbook-permissive suffix: any printable unicode, no whitespace
  defp permissive_suffix do
    :printable
    |> string(min_length: 1, max_length: 80)
    |> map(&String.replace(&1, ~r/\s/u, ""))
    |> filter(&(&1 != ""))
  end

  defp input(vector), do: Map.fetch!(vector, "doi")
end
