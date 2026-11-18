defmodule IDUtils.Schemes.OpenAlex do
  @moduledoc """
  OpenAlex ID scheme.

  See https://help.openalex.org/api/get-single-entities/#openalex-ids and
  https://www.wikidata.org/wiki/Property:P10283
  """

  @behaviour IDUtils.Scheme

  @resolver "https://openalex.org/"

  # indicates the type: work, author, source, institution, topic, keyword, publisher, funder,
  # award; concept (legacy/deprecated)
  @type_prefixes ~c"WASITKPFGC"

  # also accept in lowercase during parsing
  @valid_prefixes @type_prefixes ++ for(c <- @type_prefixes, do: c + 32)

  # Callbacks

  @doc """
  Checks whether a string is an OpenAlex ID.

  ## Examples

      iex> IDUtils.Schemes.OpenAlex.match?("https://openalex.org/P4310315706")
      true

      iex> IDUtils.Schemes.OpenAlex.match?("I121797337")
      true

      iex> IDUtils.Schemes.OpenAlex.match?("not-a-openalex-id")
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
  Normalizes an OpenAlex ID.

  ## Examples

      iex> IDUtils.Schemes.OpenAlex.normalize("https://openalex.org/works/W2741809807")
      {:ok, "W2741809807"}

      iex> IDUtils.Schemes.OpenAlex.normalize("openalex:a5068542997")
      {:ok, "A5068542997"}

      iex> IDUtils.Schemes.OpenAlex.normalize("not-a-openalex-id")
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
  Builds a URI for the given OpenAlex ID.

  ## Examples

      iex> IDUtils.Schemes.OpenAlex.build_uri("W2104101804")
      {:ok, %URI{scheme: "https", host: "openalex.org", path: "/W2104101804", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(id) when is_binary(id) do
    URI.new(@resolver <> id)
  end

  # Private helpers

  defguardp is_id_prefix(c) when c in @valid_prefixes

  defguardp is_ngroup(a, b, c, d, e, f)
            when a in ?0..?9 and b in ?0..?9 and c in ?0..?9 and d in ?0..?9 and
                   e in ?0..?9 and f in ?0..?9

  defp parse(@resolver <> "works/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "authors/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "sources/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "institutions/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "topics/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "keywords/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "publishers/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "funders/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "awards/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> "concepts/" <> rest), do: alex(rest, <<>>)
  defp parse(@resolver <> rest), do: alex(rest, <<>>)
  defp parse("http://openalex.org/" <> rest), do: alex(rest, <<>>)
  defp parse("openalex: " <> rest), do: alex(rest, <<>>)
  defp parse("openalex:" <> rest), do: alex(rest, <<>>)
  defp parse(string), do: alex(string, <<>>)

  defp alex(<<c, d, rest::binary>>, <<>> = acc) when is_id_prefix(c) and d in ?1..?9 do
    digits(rest, <<acc::binary, upper(c), d>>)
  end

  defp alex(_, _), do: :error

  defp digits(<<a, b, c, d, e, f, rest::binary>>, acc) when is_ngroup(a, b, c, d, e, f) do
    digits(rest, <<acc::binary, a, b, c, d, e, f>>)
  end

  defp digits(<<c, rest::binary>>, acc) when c in ?0..?9 do
    digits(rest, <<acc::binary, c>>)
  end

  # assume a length of prefix + 4-10 digits as per https://www.wikidata.org/wiki/Property:P10283
  # wikidata maintains their format constraint regex to account for the range of allocated ids.
  # this is current as of late 2026, and should be checked regularly.
  defp digits(<<>>, acc) when byte_size(acc) in 5..11 do
    {:ok, acc}
  end

  defp digits(_, _), do: :error

  @compile {:inline, upper: 1}
  defp upper(c) when c in ?a..?w, do: c - 32
  defp upper(c), do: c
end
