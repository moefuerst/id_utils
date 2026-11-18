defmodule IDUtils.Schemes.GND do
  @moduledoc """
  GND (Gemeinsame Normdatei) scheme.

  See https://www.wikidata.org/wiki/Property:P227
  """

  @behaviour IDUtils.Scheme

  alias IDUtils.Checksum

  @resolver "https://d-nb.info/gnd/"

  # Public API

  @doc """
  Checks whether a string starts with a GND prefix.

  ## Examples

      iex> IDUtils.Schemes.GND.prefix?("https://d-nb.info/gnd/118634313")
      true

      iex> IDUtils.Schemes.GND.prefix?("gnd:118634313")
      true

      iex> IDUtils.Schemes.GND.prefix?("118634313")
      false
  """
  @spec prefix?(binary()) :: boolean()
  def prefix?(string) when is_binary(string) do
    case strip_prefix(string) do
      :error -> false
      _rest -> true
    end
  end

  # Callbacks

  @doc """
  Checks whether a string is a GND.

  ## Examples

      iex> IDUtils.Schemes.GND.match?("118634313")
      true

      iex> IDUtils.Schemes.GND.match?("4028557-1")
      true
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, {:mod_11_weighted, base, check}} ->
        check == Checksum.mod_11_weighted(base)

      {:ok, {:mod_11_weighted_direct, base, check}} ->
        check == Checksum.mod_11_weighted_direct(base)

      :error ->
        false
    end
  end

  @doc """
  Normalizes a GND.

  ## Examples

      iex> IDUtils.Schemes.GND.normalize("http://d-nb.info/gnd/119404923")
      {:ok, "119404923"}

      iex> IDUtils.Schemes.GND.normalize("gnd:4030318-4")
      {:ok, "4030318-4"}

      iex> IDUtils.Schemes.GND.normalize("40303184")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, {:mod_11_weighted, base, check}} -> {:ok, <<base::binary, check::binary>>}
      {:ok, {:mod_11_weighted_direct, base, check}} -> {:ok, <<base::binary, ?-, check::binary>>}
      :error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given GND.

  ## Examples

      iex> IDUtils.Schemes.GND.build_uri("118823574")
      {:ok, %URI{scheme: "https", host: "d-nb.info", path: "/gnd/118823574", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(gnd) when is_binary(gnd) do
    URI.new(@resolver <> gnd)
  end

  # Private helpers

  # source: https://www.wikidata.org/wiki/Property:P227
  # wikidata maintains their format constraint regex to account for the range of (possibly?)
  # allocated gnds. this is current as of late 2026, and should be checked regularly.
  defguardp is_in_range(c) when c in ?0..?4

  defguardp is_check_digit(c) when c in ?0..?9 or c in [?x, ?X]

  defguardp is_ngroup(a, b, c, d, e, f, g)
            when a in ?0..?9 and b in ?0..?9 and c in ?0..?9 and d in ?0..?9 and e in ?0..?9 and
                   f in ?0..?9 and g in ?0..?9

  defp strip_prefix("http://d-nb.info/gnd/" <> rest), do: rest
  defp strip_prefix("https://d-nb.info/gnd/" <> rest), do: rest
  defp strip_prefix("https://lobid.org/gnd/" <> rest), do: rest
  defp strip_prefix("gnd: " <> rest), do: rest
  defp strip_prefix("gnd:" <> rest), do: rest
  defp strip_prefix("gnd/" <> rest), do: rest
  defp strip_prefix("gnd" <> rest), do: rest
  defp strip_prefix("GND: " <> rest), do: rest
  defp strip_prefix("GND:" <> rest), do: rest
  defp strip_prefix("GND" <> rest), do: rest
  defp strip_prefix("PND: " <> rest), do: rest
  defp strip_prefix("PND:" <> rest), do: rest
  defp strip_prefix("PND" <> rest), do: rest
  defp strip_prefix("SWD: " <> rest), do: rest
  defp strip_prefix("SWD:" <> rest), do: rest
  defp strip_prefix("SWD" <> rest), do: rest
  defp strip_prefix("GKD: " <> rest), do: rest
  defp strip_prefix("GKD:" <> rest), do: rest
  defp strip_prefix("GKD" <> rest), do: rest
  defp strip_prefix("(DE-588a)" <> rest), do: rest
  defp strip_prefix("(DE-588b)" <> rest), do: rest
  defp strip_prefix("(DE-588c)" <> rest), do: rest
  defp strip_prefix("(DE-588)" <> rest), do: rest
  defp strip_prefix(_other), do: :error

  defp parse(string) do
    case strip_prefix(string) do
      :error -> gnd(string)
      rest -> gnd(rest)
    end
  end

  # means it's a 'new' gnd or migrated pnd (10 chars)
  defp gnd(<<?1, r, a, b, c, d, e, f, g, x>>)
       when is_in_range(r) and is_ngroup(a, b, c, d, e, f, g) and is_check_digit(x) do
    {:ok, {:mod_11_weighted, <<?1, r, a, b, c, d, e, f, g>>, <<upper(x)>>}}
  end

  # same but with "1" prefix (9 chars)
  defp gnd(<<?1, a, b, c, d, e, f, g, x>>) when is_ngroup(a, b, c, d, e, f, g) and is_check_digit(x) do
    {:ok, {:mod_11_weighted, <<?1, a, b, c, d, e, f, g>>, <<upper(x)>>}}
  end

  defp gnd(<<?3, a, b, c, d, e, f, g, x>>) when is_ngroup(a, b, c, d, e, f, g) and is_check_digit(x) do
    {:ok, {:mod_11_weighted, <<?3, a, b, c, d, e, f, g>>, <<upper(x)>>}}
  end

  # means it's a legacy shape (8 chars)
  defp gnd(<<first, rest::binary>>) when first in ?1..?9 do
    hyphenated(rest, <<first>>)
  end

  defp gnd(_), do: :error

  defp hyphenated(<<?-, x>>, digits) when is_check_digit(x) do
    {:ok, {:mod_11_weighted_direct, digits, <<upper(x)>>}}
  end

  defp hyphenated(<<d, rest::binary>>, digits) when d in ?0..?9 and byte_size(digits) < 8 do
    hyphenated(rest, <<digits::binary, d>>)
  end

  defp hyphenated(_, _), do: :error

  @compile {:inline, upper: 1}
  defp upper(?x), do: ?X
  defp upper(c), do: c
end
