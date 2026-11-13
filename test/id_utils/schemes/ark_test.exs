defmodule IDUtils.Schemes.ARKTest do
  use IDUtils.FixtureCase, async: true

  alias IDUtils.Schemes.ARK

  @fixtures %{
    sampled_arks: ["schemes", "ark_samples.jsonc"]
  }

  doctest ARK

  describe "match?/1" do
    test "matches a string that conforms to the scheme" do
      identifier = "ark:67531/metadc927519"
      w_subparts = "ark:67531/metadc927519/m2/1"
      w_variants = "ark:67531/metadc927519/m2/1/high_res_d/971863.pdf"
      w_resolver = "https://example.org/ark:67531/metadc927519/m2/1/high_res_d/971863.pdf"

      assert ARK.match?(identifier) == true
      assert ARK.match?(w_subparts) == true
      assert ARK.match?(w_variants) == true
      assert ARK.match?(w_resolver) == true
    end

    test "rejects a NAAN that is not 5 bytes" do
      valid = "ark:67531/metadc927519"
      short = "ark:6753/metadc927519"
      tlong = "ark:675310/metadc927519"

      # sanity check
      assert ARK.match?(valid)

      refute ARK.match?(short)
      refute ARK.match?(tlong)
    end

    test "rejects names with characters not in the allowed set" do
      for c <- invalid_chars_in_name() do
        invalid_name = "meta" <> <<c::utf8>> <> "927519"

        refute ARK.match?("ark:67531/" <> invalid_name)
      end
    end

    test "rejects an empty name" do
      for identifier <- ["ark:67531/", "ark:12345//", "ark:12345/."],
          resolver <- ["", "https://example.org/"] do
        refute ARK.match?(resolver <> identifier)
      end
    end

    test "rejects non-ASCII characters" do
      # must be %-encoded
      for c <- ["é", "ü", "日", "\u200B", "\u00A0", "\u2010", "😀"] do
        refute ARK.match?("ark:67531/meta" <> c <> "927519")
      end
    end

    test "rejects malformed input" do
      for identifier <- [
            "not-an-ark:12345/x54",
            "https://example.org/?next=ark:12345/x54",
            "https://example.org/#ark:12345/x54",
            "ark:bad/ark:12345/x54"
          ] do
        refute ARK.match?(identifier)
      end
    end

    test "matches structural noise" do
      for identifier <- [
            "ark:12345/./c2.pdf",
            "ark:12345/x..54",
            "ark:12345/a.-.b",
            "ark:12345/x54//c2.pdf",
            "ark:12345/x54/c2..pdf",
            "ark:12345/x54/c2//file.pdf",
            "ark:12345/x54//c2..pdf"
          ],
          resolver <- ["", "https://example.org/"] do
        input = resolver <> identifier

        assert ARK.match?(input)
      end
    end

    test "matches sampled real-world ARKs" do
      failures =
        sampled_arks()
        |> Enum.map(&input/1)
        |> Enum.reject(&ARK.match?/1)

      assert failures == []
    end
  end

  describe "normalize/1" do
    test "strips resolver cover and returns the compact ARK" do
      result = ARK.normalize("https://example.org/ark:12345/x54xz321/s3/f8.05v.tiff")

      assert result == {:ok, "ark:12345/x54xz321/s3/f8.05v.tiff"}
    end

    test "removes legacy trailing slash label form from the bow" do
      result = ARK.normalize("ark:/12345/x54xz321")

      assert result == {:ok, "ark:12345/x54xz321"}
    end

    test "removes the identity inert hyphens" do
      result = ARK.normalize("ark:12345/141e86dc-d396-4e59-bbc2-4c3bf5326152")

      assert result == {:ok, "ark:12345/141e86dcd3964e59bbc24c3bf5326152"}
    end

    test "removes query strings" do
      for identifier <- ["ark:12345/x54", "ark:/12345/x54", "ARK:12345/x54"],
          qualifier <- ["", "/s3/f8.05v.tiff"],
          resolver <- ["", "https://example.org/"],
          query <- ["?", "?info", "?next=ark:54321/other"] do
        input = resolver <> identifier <> qualifier <> query
        expected = "ark:12345/x54" <> qualifier

        {:ok, result} = ARK.normalize(input)

        assert result == expected
      end
    end

    test "does not make an invalid name valid because of a query string" do
      for identifier <- ["ark:12345/", "ark:12345/.", "ark:12345/x%"],
          query <- ["?", "?info", "?next=ark:54321/other"] do
        input = identifier <> query

        assert ARK.normalize(input) == {:error, :invalid_identifier}
      end
    end

    test "collapses structural noise" do
      for {identifier, expected} <- [
            {"ark:12345/./c2.pdf", "ark:12345/c2.pdf"},
            {"ark:12345/x..54", "ark:12345/x.54"},
            {"ark:12345/a.-.b", "ark:12345/a.b"},
            {"ark:12345/x54//c2.pdf", "ark:12345/x54/c2.pdf"},
            {"ark:12345/x54/c2..pdf", "ark:12345/x54/c2.pdf"},
            {"ark:12345/x54/c2//file.pdf", "ark:12345/x54/c2/file.pdf"},
            {"ark:12345/x54//c2..pdf", "ark:12345/x54/c2.pdf"}
          ],
          resolver <- ["", "https://example.org/"] do
        input = resolver <> identifier

        assert ARK.normalize(input) == {:ok, expected}
      end
    end

    test "is idempotent" do
      for vector <- sampled_arks() do
        input = input(vector)

        {:ok, normalized} = ARK.normalize(input)
        {:ok, result} = ARK.normalize(normalized)

        assert result == normalized
      end
    end
  end

  describe "escape handling" do
    test "rejects incomplete and non-hex escapes in names and qualifiers" do
      for name <- ["x%", "x%7", "x%GG", "x%7g", "x%g7", "x%%20", "x%20%"],
          prefix <- ["ark:12345/", "ark:12345/name/"],
          resolver <- ["", "https://example.org/"] do
        identifier = resolver <> prefix <> name

        refute ARK.match?(identifier)
        assert ARK.normalize(identifier) == {:error, :invalid_identifier}
      end
    end

    test "preserves encoded characters and uppercases only the two escape digits" do
      for {name, expected_name} <- [
            {"x%aBcDeF", "x%ABcDeF"},
            {"x%ab%cd%ef", "x%AB%CD%EF"},
            {"%25abc", "%25abc"},
            {"%2fabc", "%2Fabc"},
            {"%2eabc", "%2Eabc"},
            {"%2dabc", "%2Dabc"},
            {"%3fabc", "%3Fabc"},
            {"x%252fabc", "x%252fabc"}
          ],
          prefix <- ["ark:12345/", "ark:12345/name/"],
          resolver <- ["", "https://example.org/"] do
        identifier = prefix <> name

        expected = prefix <> expected_name

        assert ARK.match?(resolver <> identifier)
        assert ARK.normalize(resolver <> identifier) == {:ok, expected}
        assert ARK.normalize(expected) == {:ok, expected}
      end
    end
  end

  # Private helpers

  defp input(vector), do: Map.fetch!(vector, "ark")

  defp invalid_chars_in_name do
    # https://datatracker.ietf.org/doc/html/draft-kunze-ark-44#name-character-repertoires
    valid_chars =
      [?a..?z, ?A..?Z, ?0..?9, ~c"=~*+@_$", ~c"%-./"]
      |> Enum.concat()
      |> MapSet.new()

    invalid_chars =
      for c <- 0..127,
          not MapSet.member?(valid_chars, c),
          do: c

    invalid_chars
  end
end
