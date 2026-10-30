defmodule IDUtils.Schemes.ISNI do
  @moduledoc """
  ISNI (International Standard Name Identifier) scheme.

  See https://en.wikipedia.org/wiki/International_Standard_Name_Identifier
  """

  @behaviour IDUtils.Scheme

  alias IDUtils.Checksum

  @resolver "https://isni.org/isni/"

  # Public API

  @doc """
  Checks whether a string starts with an ISNI prefix.

  ## Examples

      iex> IDUtils.Schemes.ISNI.prefix?("https://isni.org/isni/000000012146438X")
      true

      iex> IDUtils.Schemes.ISNI.prefix?("ISNI 0000 0001 2146 438X")
      true

      iex> IDUtils.Schemes.ISNI.prefix?("000000012146438X")
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
  Checks whether a string is an ISNI.

  ## Examples

      iex> IDUtils.Schemes.ISNI.match?("000000012146438X")
      true

      iex> IDUtils.Schemes.ISNI.match?("0000000121464380")
      false
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, <<base::binary-size(15), check::binary-size(1)>>} ->
        check == Checksum.mod_11_2(base)

      :error ->
        false
    end
  end

  @doc """
  Normalizes an ISNI.

  ## Examples

      iex> IDUtils.Schemes.ISNI.normalize("ISNI 0000 0001 2146 438X")
      {:ok, "000000012146438X"}

      iex> IDUtils.Schemes.ISNI.normalize("https://isni.org/isni/000000012146438X")
      {:ok, "000000012146438X"}

      iex> IDUtils.Schemes.ISNI.normalize("0000 0001 2146 438X")
      {:ok, "000000012146438X"}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, digits} -> {:ok, digits}
      :error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given ISNI.

  ## Examples

      iex> IDUtils.Schemes.ISNI.build_uri("000000012146438X")
      {:ok, %URI{scheme: "https", host: "isni.org", path: "/isni/000000012146438X", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(isni) when is_binary(isni) do
    URI.new(@resolver <> isni)
  end

  # Private helpers

  defp strip_prefix("https://isni.org/isni/" <> rest), do: rest
  defp strip_prefix("https://isni.org/" <> rest), do: rest
  defp strip_prefix("http://www.isni.org/isni/" <> rest), do: rest
  defp strip_prefix("http://isni.org/isni/" <> rest), do: rest
  defp strip_prefix("isni.org/isni/" <> rest), do: rest
  defp strip_prefix("isni.org/" <> rest), do: rest
  defp strip_prefix("isni:" <> rest), do: rest
  defp strip_prefix("ISNI|" <> rest), do: rest
  defp strip_prefix("ISNI " <> rest), do: rest
  defp strip_prefix("(isni)" <> rest), do: rest
  defp strip_prefix(_other), do: :error

  defp parse(string) do
    case strip_prefix(string) do
      :error -> isni(string, <<>>)
      rest -> isni(rest, <<>>)
    end
  end

  defp isni(<<digit, rest::binary>>, acc) when byte_size(acc) < 16 and digit in ?0..?9 do
    isni(rest, <<acc::binary, digit>>)
  end

  defp isni(<<check, rest::binary>>, acc) when byte_size(acc) == 15 and check in [?X, ?x] do
    isni(rest, <<acc::binary, ?X>>)
  end

  defp isni(<<separator, rest::binary>>, acc) when separator in [?-, ?\s] do
    isni(rest, acc)
  end

  defp isni(<<>>, acc) when byte_size(acc) == 16 do
    {:ok, acc}
  end

  defp isni(_, _), do: :error
end
