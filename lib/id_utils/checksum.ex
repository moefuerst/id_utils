defmodule IDUtils.Checksum do
  @moduledoc """
  Shared checksum algorithms for identifier schemes.
  """

  # Public API

  @doc """
  Computes a ISO 3297/ISO 2108 weighted MOD 11 check digit.

  ## Examples

      iex> IDUtils.Checksum.mod_11_weighted("0378595")
      "5"

      iex> IDUtils.Checksum.mod_11_weighted("030640615")
      "2"

      iex> IDUtils.Checksum.mod_11_weighted("0000006")
      "X"
  """
  @spec mod_11_weighted(binary()) :: binary()
  def mod_11_weighted(<<_, _::binary>> = digits) do
    total = mod_11_weighted_total(digits, byte_size(digits) + 1, 0)

    case rem(11 - rem(total, 11), 11) do
      10 -> "X"
      digit -> Integer.to_string(digit)
    end
  end

  # Private helpers

  defp mod_11_weighted_total(<<digit, rest::binary>>, weight, total) when digit in ?0..?9 do
    mod_11_weighted_total(rest, weight - 1, total + (digit - ?0) * weight)
  end

  defp mod_11_weighted_total(<<>>, _weight, total), do: total
end
