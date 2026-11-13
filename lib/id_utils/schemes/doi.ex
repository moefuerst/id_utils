defmodule IDUtils.Schemes.DOI do
  @moduledoc """
  DOI (Digital Object Identifier) scheme.

  See https://doi.org/10.1000/182

  > #### DOI Prefix {: .info}
  >
  > The 2022 edition of ISO 26324 "Information and documentation — Digital object identifier
  > system" removed the previous requirement for the directory indicator to be "10" from the
  > prefix syntax, and also allows DOI names without a registrant code. In theory, that would
  > allow for DOIs like `15434/foo-bar`. Furthermore, there is no formal restriction in the
  > ISO-standard that the registrant code must be numeric
  > [(see)](https://iana.org/assignments/urn-namespaces/urn-formal/doi).
  >
  > However, there is currently no indication that the DOI Foundation has actually allocated such
  > a prefix, and the current DOI Handbook describes the namespace as beginning with "10". This
  > module follows common practical conventions and only matches DOIs starting with the directory
  > indicator "10" and a registrant code that consists only of one or more digits (allowing for
  > registrant code subdivisions with a `.`).
  """

  @behaviour IDUtils.Scheme

  @resolver "https://doi.org/"

  # Callbacks

  @doc """
  Checks whether a string can be matched as a DOI.

  ## Examples

      iex> IDUtils.Schemes.DOI.match?("10.1234/abc123")
      true

      iex> IDUtils.Schemes.DOI.match?("https://doi.org/10.1111/foo-bar")
      true

      iex> IDUtils.Schemes.DOI.match?("not-a-doi")
      false
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, _} -> true
      :error -> false
    end
  end

  @doc """
  Normalizes a DOI.

  ## Examples

      iex> IDUtils.Schemes.DOI.normalize("https://doi.org/10.1000.10/foo-bar")
      {:ok, "10.1000.10/foo-bar"}

      iex> IDUtils.Schemes.DOI.normalize("doi: 10.1234/foo")
      {:ok, "10.1234/foo"}

      iex> IDUtils.Schemes.DOI.normalize("10.1234/abc123")
      {:ok, "10.1234/abc123"}

      iex> IDUtils.Schemes.DOI.normalize("not-a-doi")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, {prefix, suffix}} -> {:ok, format(prefix, suffix)}
      :error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given DOI.

  ## Examples

      iex> IDUtils.Schemes.DOI.build_uri("10.1234/abc123")
      {:ok, %URI{scheme: "https", host: "doi.org", path: "/10.1234/abc123", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(doi) when is_binary(doi) do
    URI.new(@resolver <> doi)
  end

  # Private helpers

  defguardp is_doi_label(d, o, i) when d in [?d, ?D] and o in [?o, ?O] and i in [?i, ?I]

  defguardp is_ngroup(a, b, c, d)
            when a in ?0..?9 and b in ?0..?9 and c in ?0..?9 and d in ?0..?9

  # excludes ASCII control chars and whitespace. while the big registration agencies now
  # restrict/recommend allowed chars for a suffix, legacy DOIs can contain basically everything,
  # see, e.g.
  # crossref.org/blog/dois-and-matching-regular-expressions
  # crossref.org/documentation/member-setup/constructing-your-dois/suffixes-containing-special-characters
  defguardp is_valid_suffix_byte(c) when c not in 0x00..?\s and c != 0x7F

  defp parse(@resolver <> rest), do: doi(rest)
  defp parse("http://doi.org/" <> rest), do: doi(rest)
  defp parse("https://dx.doi.org/" <> rest), do: doi(rest)
  defp parse("http://dx.doi.org/" <> rest), do: doi(rest)
  defp parse("dx.doi.org/" <> rest), do: doi(rest)
  defp parse("doi.org/" <> rest), do: doi(rest)
  defp parse("info:doi/" <> rest), do: doi(rest)
  defp parse("urn:doi:" <> rest), do: doi(rest)
  defp parse(<<d, o, i, ":", ?\s, rest::binary>>) when is_doi_label(d, o, i), do: doi(rest)
  defp parse(<<d, o, i, ":", rest::binary>>) when is_doi_label(d, o, i), do: doi(rest)
  defp parse(string), do: doi(string)

  defp doi("10." <> rest) do
    case registrant_code(rest, <<>>) do
      {:ok, code, suffix} -> {:ok, {"10." <> code, suffix}}
      _ -> :error
    end
  end

  defp doi(_), do: :error

  # fast-path 4 digits while the acc is still short, because in practice there are basically no
  # cases where the code is not 4+ digits
  defp registrant_code(<<a, b, c, d, rest::binary>>, acc) when is_ngroup(a, b, c, d) and byte_size(acc) < 4 do
    registrant_code(rest, <<acc::binary, a, b, c, d>>)
  end

  # hit the slash: validate registrant code is non-empty
  defp registrant_code(<<?/, rest::binary>>, acc) when byte_size(acc) >= 1 do
    suffix(rest, acc, <<>>)
  end

  # avoid `..` and registrant code ending with a `.`
  defp registrant_code(<<?., c, rest::binary>>, acc) when c in ?0..?9 and byte_size(acc) >= 1 do
    registrant_code(rest, <<acc::binary, ?., c>>)
  end

  defp registrant_code(<<c, rest::binary>>, acc) when c in ?0..?9 do
    registrant_code(rest, <<acc::binary, c>>)
  end

  defp registrant_code(_, _), do: :error

  defp suffix(<<c, rest::binary>>, code, acc) when is_valid_suffix_byte(c) do
    suffix(rest, code, <<acc::binary, c>>)
  end

  defp suffix(<<>>, code, acc) when byte_size(acc) > 0 do
    {:ok, code, acc}
  end

  defp suffix(_, _, _), do: :error

  defp format(prefix, suffix) do
    prefix <> "/" <> fold_doi_case(suffix, <<>>)
  end

  # lowercase A..Z only
  defp fold_doi_case(<<c, rest::binary>>, acc) when c in ?A..?Z do
    fold_doi_case(rest, <<acc::binary, c + 32>>)
  end

  defp fold_doi_case(<<c, rest::binary>>, acc) do
    fold_doi_case(rest, <<acc::binary, c>>)
  end

  defp fold_doi_case(<<>>, acc) do
    acc
  end
end
