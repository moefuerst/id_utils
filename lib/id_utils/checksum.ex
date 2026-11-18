defmodule IDUtils.Checksum do
  @moduledoc false
  # Shared checksum algorithms for identifier schemes.

  @betanumeric "0123456789bcdfghjkmnpqrstvwxz"
  @betanumeric_ordinals @betanumeric
                        |> :binary.bin_to_list()
                        |> Enum.with_index()
                        |> Map.new()

  # Internal API

  @doc """
  Computes an ISO 7064 MOD 11-2 check digit.

  This function expects a string of digits, excluding the check digit and separators.

  ## Examples

      iex> IDUtils.Checksum.mod_11_2("000000021825009")
      "7"

      iex> IDUtils.Checksum.mod_11_2("000000021694233")
      "X"
  """
  @spec mod_11_2(binary()) :: binary()
  def mod_11_2(<<_, _::binary>> = digits) do
    sum = mod_11_2_sum(digits, 0)

    (12 - Integer.mod(sum, 11))
    |> Integer.mod(11)
    |> to_mod_11_check_digit()
  end

  @doc """
  Computes a weighted MOD 11 check digit.

  Weights are derived from the input length. For an `n`-digit payload, weights descend from `n +
  1` to `2`, the appended check digit has weight `1`. Used in schemes such as ISSN (ISO 3297),
  ISBN-10 (ISO 2108), or GND/PPN.

  This function expects a string of digits, excluding the check digit and separators. Callers
  own length validation.

  ## Examples

      iex> IDUtils.Checksum.mod_11_weighted("0378595")
      "5"

      iex> IDUtils.Checksum.mod_11_weighted("0000006")
      "X"

      iex> IDUtils.Checksum.mod_11_weighted("030640615")
      "2"
  """
  @spec mod_11_weighted(binary()) :: binary()
  def mod_11_weighted(<<_, _::binary>> = digits) do
    weight = byte_size(digits) + 1
    sum = mod_11_weighted_sum(digits, weight, 0)

    (11 - Integer.mod(sum, 11))
    |> Integer.mod(11)
    |> to_mod_11_check_digit()
  end

  @doc """
  Computes a weighted MOD 11 check digit, using the remainder.

  Weights are derived from the input length. For an `n`-digit payload, weights descend from `n +
  1` to `2`. Unlike `mod_11_weighted/1`, the check digit is the weighted sum modulo 11 itself, not
  its complement, so it does not satisfy a "sum including the check character is divisible by 11"
  rule. Used by pre-GND SWD and GKD numbers (See
  ["Prüfziffernberechnung"](https://wiki.dnb.de/spaces/ILTIS/pages/48139522/Prüfziffernberechnung).

  This function expects a string of digits, excluding the check character and separators. Callers
  own length validation.

  ## Examples

      iex> IDUtils.Checksum.mod_11_weighted_direct("95980479")
      "1"

      iex> IDUtils.Checksum.mod_11_weighted_direct("4030318")
      "4"

      iex> IDUtils.Checksum.mod_11_weighted_direct("4028557")
      "1"
  """
  @spec mod_11_weighted_direct(binary()) :: binary()
  def mod_11_weighted_direct(<<_, _::binary>> = digits) do
    weight = byte_size(digits) + 1

    digits
    |> mod_11_weighted_sum(weight, 0)
    |> Integer.mod(11)
    |> to_mod_11_check_digit()
  end

  @doc """
  Computes an ISO 7064 MOD 97-10 check digit pair.

  This function expects a string of digits, excluding the check digits.

  ## Examples

      iex> IDUtils.Checksum.mod_97_10("88649142")
      "94"
  """
  @spec mod_97_10(binary()) :: binary()
  def mod_97_10(<<_, _::binary>> = digits) do
    sum = mod_97_10_sum(digits, 0)

    (98 - Integer.mod(sum * 10, 97))
    |> Integer.to_string()
    |> String.pad_leading(2, "0")
  end

  @doc """
  Computes a NCDA weighted MOD 29 check character.

  This function expects an identifier string exactly as written including separators, excluding
  the check character. Characters outside the NOID betanumeric character repertoire (such as `/`)
  contribute zero to the sum but still count toward position, so removing them changes the result.
  Widely used with the ARK scheme, sometimes also with Handle or DOI.

  ## Examples

      iex> IDUtils.Checksum.ncda("13030xf93gt2")
      "j"

      iex> IDUtils.Checksum.ncda("13030/xf93gt2")
      "q"

      iex> IDUtils.Checksum.ncda("")
      "0"
  """
  @spec ncda(binary()) :: binary()
  def ncda(payload) when is_binary(payload) do
    sum = ncda_sum(payload, 1, 0)

    sum
    |> Integer.mod(29)
    |> to_ncda_check_char()
  end

  # Private helpers

  defp mod_11_2_sum(<<digit, rest::binary>>, acc) when digit in ?0..?9 do
    mod_11_2_sum(rest, (acc + digit - ?0) * 2)
  end

  defp mod_11_2_sum(<<>>, acc), do: acc

  defp mod_11_weighted_sum(<<digit, rest::binary>>, weight, acc) when digit in ?0..?9 do
    mod_11_weighted_sum(rest, weight - 1, acc + (digit - ?0) * weight)
  end

  defp mod_11_weighted_sum(<<>>, _weight, acc), do: acc

  defp to_mod_11_check_digit(n) when n in 0..9, do: <<?0 + n>>
  defp to_mod_11_check_digit(10), do: "X"

  defp mod_97_10_sum(<<digit, rest::binary>>, acc) when digit in ?0..?9 do
    mod_97_10_sum(rest, Integer.mod((acc + digit - ?0) * 10, 97))
  end

  defp mod_97_10_sum(<<>>, acc), do: acc

  defp ncda_sum(<<byte, rest::binary>>, position, acc) do
    value = Map.get(@betanumeric_ordinals, byte, 0)

    ncda_sum(rest, position + 1, acc + value * position)
  end

  defp ncda_sum(<<>>, _position, acc), do: acc

  defp to_ncda_check_char(n) when n in 0..28, do: binary_part(@betanumeric, n, 1)
end
