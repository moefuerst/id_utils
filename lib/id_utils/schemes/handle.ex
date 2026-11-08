defmodule IDUtils.Schemes.Handle do
  @moduledoc """
  Handle System scheme.

  See https://www.rfc-editor.org/info/rfc3651/
  """

  @behaviour IDUtils.Scheme

  @resolver "https://hdl.handle.net/"

  # Public API

  @doc """
  Checks whether a string starts with a Handle prefix.

  ## Examples

      iex> IDUtils.Schemes.Handle.prefix?("https://hdl.handle.net/20.1000/100")
      true

      iex> IDUtils.Schemes.Handle.prefix?("info:hdl/20.1000/100")
      true

      iex> IDUtils.Schemes.Handle.prefix?("20.1000/100")
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
  Checks whether a string can be matched as a Handle.

  ## Examples

      iex> IDUtils.Schemes.Handle.match?("20.1000/100")
      true

      iex> IDUtils.Schemes.Handle.match?("https://hdl.handle.net/20.1000/5555")
      true

      iex> IDUtils.Schemes.Handle.match?("not-a-handle")
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
  Normalizes a Handle.

  ## Examples

      iex> IDUtils.Schemes.Handle.normalize("20.1000/5555")
      {:ok, "20.1000/5555"}

      iex> IDUtils.Schemes.Handle.normalize("https://hdl.handle.net/20.1000/5555")
      {:ok, "20.1000/5555"}

      iex> IDUtils.Schemes.Handle.normalize("hdl: 2381/12345")
      {:ok, "2381/12345"}

      iex> IDUtils.Schemes.Handle.normalize("not-a-handle")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, {naming_authority, local_name}} -> {:ok, format(naming_authority, local_name)}
      :error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given Handle.

  ## Examples

      iex> IDUtils.Schemes.Handle.build_uri("20.1000/5555")
      {:ok, %URI{scheme: "https", host: "hdl.handle.net", path: "/20.1000/5555", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(handle) when is_binary(handle) do
    URI.new(@resolver <> handle)
  end

  # Private helpers

  defguardp is_handle_label(h, d, l) when h in [?h, ?H] and d in [?d, ?D] and l in [?l, ?L]

  defguardp is_reserved_byte(c) when c in [?., ?/, ?@]

  defp strip_prefix(@resolver <> rest), do: rest
  defp strip_prefix("http://hdl.handle.net/" <> rest), do: rest
  defp strip_prefix("hdl.handle.net/" <> rest), do: rest
  defp strip_prefix("info:hdl/" <> rest), do: rest
  defp strip_prefix(<<h, d, l, ":", ?\s, rest::binary>>) when is_handle_label(h, d, l), do: rest
  defp strip_prefix(<<h, d, l, ":", rest::binary>>) when is_handle_label(h, d, l), do: rest
  defp strip_prefix(_other), do: :error

  defp parse(string) do
    case strip_prefix(string) do
      :error -> handle(string)
      rest -> handle(rest)
    end
  end

  defp handle(<<c, _rest::binary>> = value) when not is_reserved_byte(c) do
    case naming_authority(value, <<>>) do
      {:ok, naming_authority, local_name} -> {:ok, {naming_authority, local_name}}
      _ -> :error
    end
  end

  defp handle(_), do: :error

  # hit the slash: validate naming authority is non-empty
  defp naming_authority(<<?/, rest::binary>>, acc) when byte_size(acc) >= 1 do
    local_name(rest, acc, <<>>)
  end

  # avoid `..`, empty naming authority segments
  defp naming_authority(<<?., c, rest::binary>>, acc) when not is_reserved_byte(c) and byte_size(acc) >= 1 do
    naming_authority(rest, <<acc::binary, ?., c>>)
  end

  defp naming_authority(<<c, rest::binary>>, acc) when not is_reserved_byte(c) do
    naming_authority(rest, <<acc::binary, c>>)
  end

  defp naming_authority(_, _), do: :error

  defp local_name(<<c, rest::binary>>, naming_authority, acc) do
    local_name(rest, naming_authority, <<acc::binary, c>>)
  end

  # strictly speaking, the `acc < 0` guard deviates from the ABNF grammar in the RFC, where local
  # name can be zero-length: `<LocalName> = *(%x00-FF)`
  # the conceptual definition specifies that every handle "consists of two parts: its naming
  # authority, followed by a unique local name under the naming authority."
  defp local_name(<<>>, naming_authority, acc) when byte_size(acc) > 0 do
    {:ok, naming_authority, acc}
  end

  defp local_name(_, _, _), do: :error

  defp format(naming_authority, local_name) do
    naming_authority <> "/" <> local_name
  end
end
