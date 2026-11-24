defmodule IDUtils.Schemes.VIAF do
  @moduledoc """
  VIAF (Virtual International Authority File) scheme.

  See https://www.wikidata.org/wiki/Property:P214
  """

  @behaviour IDUtils.Scheme

  @resolver "https://viaf.org/viaf/"

  # Public API

  @doc """
  Checks whether a string starts with a VIAF prefix.

  ## Examples

      iex> IDUtils.Schemes.VIAF.prefix?("http://viaf.org/viaf/24609378")
      true

      iex> IDUtils.Schemes.VIAF.prefix?("viaf:24609378")
      true

      iex> IDUtils.Schemes.VIAF.prefix?("24609378")
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
  Checks whether a string is a VIAF ID.

  ## Examples

      iex> IDUtils.Schemes.VIAF.match?("http://viaf.org/viaf/9972147907520779210008")
      true

      iex> IDUtils.Schemes.VIAF.match?("24609378")
      true

      iex> IDUtils.Schemes.VIAF.match?("not-a-viaf-id")
      false
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, _id} -> true
      :error -> false
    end
  end

  @doc """
  Normalizes a VIAF ID.

  ## Examples

      iex> IDUtils.Schemes.VIAF.normalize("http://viaf.org/viaf/2736702")
      {:ok, "2736702"}

      iex> IDUtils.Schemes.VIAF.normalize("VIAF:70596852")
      {:ok, "70596852"}

      iex> IDUtils.Schemes.VIAF.normalize("not-a-viaf-id")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, id} -> {:ok, id}
      :error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given VIAF ID.

  ## Examples

      iex> IDUtils.Schemes.VIAF.build_uri("238999862")
      {:ok, %URI{scheme: "https", host: "viaf.org", path: "/viaf/238999862", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(id) when is_binary(id) do
    URI.new(@resolver <> id)
  end

  # Private helpers

  # assume length of either 2-9 or 19-22 digits as per https://www.wikidata.org/wiki/Property:P214
  # wikidata maintains their format constraint regex to account for the range of allocated ids.
  # this is current as of late 2026, and should be checked regularly.
  defguardp is_valid_size(acc) when byte_size(acc) in 2..9 or byte_size(acc) in 19..22

  defguardp is_ngroup(a, b, c, d, e, f, g)
            when a in ?0..?9 and b in ?0..?9 and c in ?0..?9 and d in ?0..?9 and
                   e in ?0..?9 and f in ?0..?9 and g in ?0..?9

  defp strip_prefix("https://viaf.org/viaf/" <> rest), do: rest
  defp strip_prefix("http://www.viaf.org/viaf/" <> rest), do: rest
  defp strip_prefix("http://viaf.org/viaf/" <> rest), do: rest
  defp strip_prefix("viaf: " <> rest), do: rest
  defp strip_prefix("viaf:" <> rest), do: rest
  defp strip_prefix("VIAF: " <> rest), do: rest
  defp strip_prefix("VIAF:" <> rest), do: rest
  defp strip_prefix(_other), do: :error

  defp parse(string) do
    case strip_prefix(string) do
      :error -> viaf(string, <<>>)
      rest -> viaf(rest, <<>>)
    end
  end

  defp viaf(<<c, d, rest::binary>>, <<>> = acc) when c in ?1..?9 and d in ?0..?9 do
    digits(rest, <<acc::binary, c, d>>)
  end

  defp viaf(_, _), do: :error

  defp digits(<<a, b, c, d, e, f, g, rest::binary>>, acc) when is_ngroup(a, b, c, d, e, f, g) do
    digits(rest, <<acc::binary, a, b, c, d, e, f, g>>)
  end

  defp digits(<<c, rest::binary>>, acc) when c in ?0..?9 do
    digits(rest, <<acc::binary, c>>)
  end

  defp digits(<<>>, acc) when is_valid_size(acc) do
    {:ok, acc}
  end

  defp digits(_, _), do: :error
end
