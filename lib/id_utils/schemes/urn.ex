defmodule IDUtils.Schemes.URN do
  @moduledoc """
  URN (Uniform Resource Name) scheme.

  For the purposes of this library, an URN is considered "valid" if its namespace identifier is
  registered with the IANA as "formal". Registered "informal" namespace identifiers will not
  match.

  See https://www.rfc-editor.org/info/rfc8141/
  """

  @behaviour IDUtils.Scheme

  @nids_file Path.join(["priv", "urn_namespaces.exs"])
  @external_resource @nids_file

  @iana_formal_nids @nids_file
                    |> File.read!()
                    |> Code.string_to_quoted!()

  # Public API

  @doc """
  Returns all URN NIDs registered as "formal" with IANA.

  The dataset is sourced from the
  [IANA Registry of URN Namespaces](https://www.iana.org/assignments/urn-namespaces) and covers
  all formal namespace identifiers registered as of the release date of this version of IDUtils.
  """
  @spec namespaces() :: [binary()]
  def namespaces, do: @iana_formal_nids

  # Callbacks

  @doc """
  Check whether a string is a URN.

  ## Examples

      iex> IDUtils.Schemes.URN.match?("urn:ietf:rfc:2648")
      true

      iex> IDUtils.Schemes.URN.match?("urn:nbn:at:AT-UBG:3-13")
      true

      iex> IDUtils.Schemes.URN.match?("urn:unregistered:foo:bar")
      false

      iex> IDUtils.Schemes.URN.match?("https://nbn-resolving.org/urn:nbn:at:AT-UBG:3-13")
      false
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, {_nid, _nss}} -> true
      :error -> false
    end
  end

  @doc """
  Normalizes a URN.

  ## Examples

      iex> IDUtils.Schemes.URN.normalize("URN:NBN:fi-fe19981001")
      {:ok, "urn:nbn:fi-fe19981001"}

      iex> IDUtils.Schemes.URN.normalize("example.com/URN:NBN:fi-fe19981001")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, {nid, nss}} -> normalize_uri_string(format(nid, nss))
      :error -> {:error, :invalid_identifier}
    end
  end

  # Private helpers

  defp parse(string) do
    case URI.new(string) do
      {:ok, %URI{path: nil}} -> :error
      {:ok, %URI{scheme: scheme}} when scheme != "urn" -> :error
      {:ok, %URI{path: path}} -> nid(path)
      _ -> :error
    end
  end

  # generate a lowercase and uppercase matching function for each nid
  for nid <- Module.get_attribute(__MODULE__, :iana_formal_nids) do
    defp nid(<<unquote(nid), ?:, rest::binary>>), do: nss(rest, unquote(nid))

    uppercase_nid = String.upcase(nid)
    defp nid(<<unquote(uppercase_nid), ?:, rest::binary>>), do: nss(rest, unquote(nid))
  end

  defp nid(_), do: :error

  defp nss(<<_, _::binary>> = nss, nid), do: {:ok, {nid, nss}}
  defp nss(_, _), do: :error

  defp normalize_uri_string(string) do
    case :uri_string.normalize(string) do
      {:error, _reason, _debug} -> {:error, :invalid_identifier}
      normalized -> {:ok, normalized}
    end
  end

  defp format(nid, nss) do
    "urn:" <> nid <> ":" <> nss
  end
end
