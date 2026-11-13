defmodule IDUtils.Schemes.ISSN do
  @moduledoc """
  ISSN (International Standard Serial Number) scheme.

  See https://en.wikipedia.org/wiki/ISSN
  """

  @behaviour IDUtils.Scheme

  alias IDUtils.Checksum

  # Callbacks

  @doc """
  Checks whether a string is an ISSN.

  ## Examples

      iex> IDUtils.Schemes.ISSN.match?("2049-3630")
      true

      iex> IDUtils.Schemes.ISSN.match?("20493630")
      true

      iex> IDUtils.Schemes.ISSN.match?("1234-567X")
      false
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, <<base::binary-size(7), check::binary-size(1)>>} ->
        check == Checksum.mod_11_weighted(base)

      :error ->
        false
    end
  end

  @doc """
  Normalizes an ISSN.

  ## Examples

      iex> IDUtils.Schemes.ISSN.normalize("2049-3630")
      {:ok, "2049-3630"}

      iex> IDUtils.Schemes.ISSN.normalize("1234 567X")
      {:ok, "1234-567X"}

      iex> IDUtils.Schemes.ISSN.normalize("not-a-issn")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, digits} -> {:ok, format(digits)}
      :error -> {:error, :invalid_identifier}
    end
  end

  # Private helpers

  defguardp is_ngroup(a, b, c, d)
            when a in ?0..?9 and b in ?0..?9 and c in ?0..?9 and d in ?0..?9

  # discarded in normalization
  defguardp is_separator(c)
            when c in [?-, ?\s]

  defp parse(string, acc \\ <<>>)

  # 8 characters: 7 digits plus check digit
  defp parse(<<>>, acc) when byte_size(acc) == 8 do
    {:ok, acc}
  end

  # a separator is only allowed between the two groups of four digits
  defp parse(<<separator, rest::binary>>, acc) when byte_size(acc) == 4 and is_separator(separator) do
    chars(rest, acc)
  end

  defp parse(rest, acc) do
    chars(rest, acc)
  end

  # at most 4 accumulated bytes leave room for a four-byte group of digits
  defp chars(<<a, b, c, d, rest::binary>>, acc) when byte_size(acc) <= 4 and is_ngroup(a, b, c, d) do
    parse(rest, <<acc::binary, a, b, c, d>>)
  end

  defp chars(<<digit, rest::binary>>, acc) when byte_size(acc) < 8 and digit in ?0..?9 do
    parse(rest, <<acc::binary, digit>>)
  end

  defp chars(<<check, rest::binary>>, acc) when byte_size(acc) == 7 and check in [?X, ?x] do
    parse(rest, <<acc::binary, ?X>>)
  end

  defp chars(_, _), do: :error

  defp format(<<a::binary-size(4), b::binary-size(4)>>) do
    a <> "-" <> b
  end
end
