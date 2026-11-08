defmodule IDUtils.Schemes.RAID do
  @moduledoc """
  RAID (Research Activity Identifier) scheme.

  See https://documentation.raid.org/raid

  > #### RAID and DOI {: .info}
  > RAID registration agencies issue RAIDs [as DOIs via
  > DataCite](https://support.datacite.org/docs/raids), reusing the DOI `10.xxxx/yyyy`
  > namespace. RAID and a DOI are therefore format-identical; the only reliable disambiguator is a
  > possible `https://raid.org/` resolver prefix.
  >
  > Since every RAID is a DOI, but not every DOI is a RAID and DOIs are much more common, IDUtils
  > prefers DOI over RAID when both are detected.
  """

  @behaviour IDUtils.Scheme

  alias IDUtils.Schemes.DOI

  @resolver "https://raid.org/"

  # Public API

  @doc """
  Checks whether a string starts with a RAID prefix.

  ## Examples

      iex> IDUtils.Schemes.RAID.prefix?("https://raid.org/10.5281/zenodo.15293455")
      true

      iex> IDUtils.Schemes.RAID.prefix?("10.5281/zenodo.15293455")
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
  Checks whether a string can be matched as a RAID.

  ## Examples

      iex> IDUtils.Schemes.RAID.match?("10.5281/zenodo.15293455")
      true

      iex> IDUtils.Schemes.RAID.match?("https://raid.org/10.5281/zenodo.15293455")
      true

      iex> IDUtils.Schemes.RAID.match?("not-a-raid")
      false
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, _} -> true
      _error -> false
    end
  end

  @doc """
  Normalizes a RAID.

  ## Examples

      iex> IDUtils.Schemes.RAID.normalize("10.5281/zenodo.15293455")
      {:ok, "10.5281/zenodo.15293455"}

      iex> IDUtils.Schemes.RAID.normalize("https://raid.org/10.1000.10/foo-bar")
      {:ok, "10.1000.10/foo-bar"}

      iex> IDUtils.Schemes.RAID.normalize("not-a-raid")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, raid} -> {:ok, raid}
      _error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given RAID.

  ## Examples

      iex> IDUtils.Schemes.RAID.build_uri("10.1234/abc123")
      {:ok, %URI{scheme: "https", host: "raid.org", path: "/10.1234/abc123", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(raid) when is_binary(raid) do
    URI.new(@resolver <> raid)
  end

  # Private helpers

  defp strip_prefix(@resolver <> rest), do: rest
  defp strip_prefix(_other), do: :error

  defp parse(string) do
    case strip_prefix(string) do
      :error -> doi(string)
      rest -> doi(rest)
    end
  end

  # RAID and a DOI are format-identical; DOI normalization equals parsing
  @spec doi(binary()) :: {:ok, binary()} | {:error, term()}
  defp doi(string), do: DOI.normalize(string)
end
