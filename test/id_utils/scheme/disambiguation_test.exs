defmodule IDUtils.Scheme.DisambiguationTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias IDUtils.Scheme.Catalog
  alias IDUtils.Scheme.Disambiguation

  describe "apply/2" do
    property "the result is an ordered subsequence of the original matches" do
      check all(schemes <- scheme_list(), value <- value()) do
        result = Disambiguation.apply(schemes, value)

        refute Keyword.has_key?(List.myers_difference(schemes, result), :ins)
      end
    end

    property "scheme suppression is independent of match order" do
      check all(
              schemes <- scheme_list(),
              reordered <- shuffle(schemes),
              value <- value()
            ) do
        result = Disambiguation.apply(schemes, value)
        reordered_result = Disambiguation.apply(reordered, value)

        assert Enum.frequencies(result) == Enum.frequencies(reordered_result)
      end
    end

    property "unrelated matches retain their order" do
      check all(schemes <- scheme_list(), value <- value()) do
        supressed = [:url, :issn, :handle, :raid]

        result = Disambiguation.apply(schemes, value)

        assert Enum.reject(result, &(&1 in supressed)) == Enum.reject(schemes, &(&1 in supressed))
      end
    end

    property "scheme suppression is idempotent" do
      check all(schemes <- scheme_list(), value <- value()) do
        result = Disambiguation.apply(schemes, value)

        assert Disambiguation.apply(result, value) == result
      end
    end
  end

  describe "clash resolution" do
    test "URL matches supress unprefixed Handle matches" do
      # unknown resolver/handle proxy -> can't be sure it is a handle
      value = "https://example.com/20.1000/100"
      schemes = [:handle, :url]

      result = Disambiguation.apply(schemes, value)

      assert result == [:url]
    end

    test "URL matches do not supress prefixed Handle matches" do
      value = "https://hdl.handle.net/20.1000/100"
      schemes = [:handle, :url]

      result = Disambiguation.apply(schemes, value)

      assert result == [:handle, :url]
    end

    test "DOI matches supress unprefixed RAID matches" do
      # raid and a doi are format-identical -> can't be sure it's a raid
      # every raid is a doi, so prefer doi over raid
      value = "10.1234/abc123"
      schemes = [:doi, :raid]

      result = Disambiguation.apply(schemes, value)

      assert result == [:doi]
    end

    test "DOI matches do not supress prefixed RAID matches" do
      value = "https://raid.org/10.1234/abc123"
      schemes = [:doi, :raid]

      result = Disambiguation.apply(schemes, value)

      assert result == [:doi, :raid]
    end
  end

  # Private helpers

  defp scheme_list do
    gen all(
          schemes <- shuffle(Catalog.list()),
          count <- integer(0..length(schemes))
        ) do
      Enum.take(schemes, count)
    end
  end

  defp value do
    one_of([
      binary(),
      map(binary(), &("https://example.com/" <> &1)),
      map(binary(), &("https://raid.org/" <> &1)),
      map(binary(), &("https://hdl.handle.net/" <> &1)),
      map(binary(), &("https://isni.org/isni/" <> &1))
    ])
  end
end
