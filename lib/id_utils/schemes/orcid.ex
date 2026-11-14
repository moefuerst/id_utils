defmodule IDUtils.Schemes.ORCID do
  @moduledoc """
  ORCID (Open Researcher and Contributor ID) scheme.

  See https://support.orcid.org/hc/en-us/articles/360006897674-Structure-of-the-ORCID-Identifier

  > #### ORCID and ISNI {: .info}
  > ORCID’s format is compatible with ISO 27729 that standardises ISNI. ORCID, Inc., the governing
  > nonprofit, is an accredited ISNI Registration Agency, and two reserved numeric blocks within
  > the ISNI range are dedicated to ORCID-issued identifiers. ORCIDs are frequently matched into
  > corresponding ISNI records, however, there is no guarantee
  > [(see)](https://casrai.org/guides/isni-identifier-explained-vs-orcid).
  """

  @behaviour IDUtils.Scheme

  alias IDUtils.Checksum
  alias IDUtils.Schemes.ISNI

  @resolver "https://orcid.org/"

  # Valid ORCID ISNI block ranges
  @original_block 15_000_000..35_000_000
  @additional_block 900_000_000_000..900_100_000_000

  # Callbacks

  @doc """
  Checks whether a string is an ORCID.

  ## Examples

      iex> IDUtils.Schemes.ORCID.match?("0000-0002-1825-0097")
      true

      iex> IDUtils.Schemes.ORCID.match?("https://orcid.org/0000-0002-1694-233X")
      true

      iex> IDUtils.Schemes.ORCID.match?("0000 0002 1825 0097")
      true

      iex> IDUtils.Schemes.ORCID.match?("0008-9999-9999-9996")
      false
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, <<base::binary-size(15), check::binary-size(1)>>} ->
        in_valid_block?(base) and check == Checksum.mod_11_2(base)

      :error ->
        false
    end
  end

  @doc """
  Normalizes an ORCID.

  ## Examples

      iex> IDUtils.Schemes.ORCID.normalize("0000-0002-1825-0097")
      {:ok, "0000-0002-1825-0097"}

      iex> IDUtils.Schemes.ORCID.normalize("0000000218250097")
      {:ok, "0000-0002-1825-0097"}

      iex> IDUtils.Schemes.ORCID.normalize("0000 0002 1825 0097")
      {:ok, "0000-0002-1825-0097"}

      iex> IDUtils.Schemes.ORCID.normalize("https://orcid.org/0000-0002-1825-0097")
      {:ok, "0000-0002-1825-0097"}

      iex> IDUtils.Schemes.ORCID.normalize("not-an-orcid")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, digits} -> {:ok, format(digits)}
      :error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given ORCID.

  ## Examples

      iex> IDUtils.Schemes.ORCID.build_uri("0000-0002-1825-0097")
      {:ok, %URI{scheme: "https", host: "orcid.org", path: "/0000-0002-1825-0097", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(orcid) do
    URI.new(@resolver <> orcid)
  end

  # Private helpers

  defguardp is_orcid_label(o, r, c, i, d)
            when o in [?o, ?O] and r in [?r, ?R] and c in [?c, ?C] and i in [?i, ?I] and d in [?d, ?D]

  defp parse(@resolver <> rest), do: orcid(rest)
  defp parse("http://orcid.org/" <> rest), do: orcid(rest)
  defp parse("orcid.org/" <> rest), do: orcid(rest)
  defp parse(<<o, r, c, i, d, ":", ?\s, rest::binary>>) when is_orcid_label(o, r, c, i, d), do: orcid(rest)
  defp parse(<<o, r, c, i, d, ":", rest::binary>>) when is_orcid_label(o, r, c, i, d), do: orcid(rest)
  defp parse(string), do: orcid(string)

  # ORCID’s format is ISO 27729 compatible
  @spec orcid(binary()) :: {:ok, binary()} | :error
  def orcid(string), do: ISNI.parse_digits(string)

  defp in_valid_block?(base) do
    number = String.to_integer(base)

    number in @original_block or number in @additional_block
  end

  defp format(<<a::binary-size(4), b::binary-size(4), c::binary-size(4), d::binary-size(4)>>) do
    a <> "-" <> b <> "-" <> c <> "-" <> d
  end
end
