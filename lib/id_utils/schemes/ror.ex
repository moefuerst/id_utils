defmodule IDUtils.Schemes.ROR do
  @moduledoc """
  ROR (Research Organization Registry) scheme.

  See https://ror.readme.io/docs/identifier
  """

  @behaviour IDUtils.Scheme

  alias IDUtils.Checksum

  @resolver "https://ror.org/"

  @crockford_base_32 ~c"0123456789ABCDEFGHJKMNPQRSTVWXYZ"

  # also accept the alphabet(A-Z) in lowercase during parsing and decoding
  @valid_chars @crockford_base_32 ++ for(c <- @crockford_base_32, c in ?A..?Z, do: c + 32)

  # Callbacks

  @doc """
  Checks whether a string is a ROR.

  ## Examples

      iex> IDUtils.Schemes.ROR.match?("00a8p0m24")
      true

      iex> IDUtils.Schemes.ROR.match?("https://ror.org/03prydq77")
      true

      iex> IDUtils.Schemes.ROR.match?("03prydq78")
      false
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, {_id, check, decoded}} -> check == Checksum.mod_97_10(decoded)
      :error -> false
    end
  end

  @doc """
  Normalizes a ROR.

  ## Examples

      iex> IDUtils.Schemes.ROR.normalize("019WHTA54")
      {:ok, "019whta54"}

      iex> IDUtils.Schemes.ROR.normalize("https://ror.org/02s376052")
      {:ok, "02s376052"}

      iex> IDUtils.Schemes.ROR.normalize("not-a-ror")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, {id, _check, _decoded}} -> {:ok, String.downcase(id)}
      :error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given ROR.

  ## Examples

      iex> IDUtils.Schemes.ROR.build_uri("02feahw73")
      {:ok, %URI{scheme: "https", host: "ror.org", path: "/02feahw73", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(ror) do
    URI.new(@resolver <> ror)
  end

  # Private helpers

  defguardp is_base(a, b, c, d, e, f)
            when a in @valid_chars and b in @valid_chars and
                   c in @valid_chars and d in @valid_chars and
                   e in @valid_chars and f in @valid_chars

  defguardp is_check(x, y) when x in ?0..?9 and y in ?0..?9

  # generate a decoding function for each valid char. this approach follows
  # github.com/xinz/crockford_base32/blob/c4b8d625ee58b5806521f65c403e4e5f5124291d/lib/symbol.ex
  for {char, value} <- Enum.with_index(Module.get_attribute(__MODULE__, :crockford_base_32)) do
    defp d(unquote(char)), do: unquote(value)

    if char in ?A..?Z do
      defp d(unquote(char + 32)), do: unquote(value)
    end
  end

  defp parse(@resolver <> rest), do: ror(rest)
  defp parse("http://ror.org/" <> rest), do: ror(rest)
  defp parse("ror.org/" <> rest), do: ror(rest)
  defp parse(string), do: ror(string)

  # id pattern: leading zero, 6 chars in the crockford base32 alphabet, 2 check digits
  defp ror(<<?0, a, b, c, d, e, f, x, y>> = id) when is_base(a, b, c, d, e, f) and is_check(x, y) do
    # six base32 digits are 5 bits each, pack them into a single 30-bit integer
    <<n::30>> = <<d(a)::5, d(b)::5, d(c)::5, d(d)::5, d(e)::5, d(f)::5>>

    {:ok, {id, <<x, y>>, Integer.to_string(n)}}
  end

  defp ror(_), do: :error
end
