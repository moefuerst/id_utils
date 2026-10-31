defmodule IDUtils.Schemes.ARK do
  @moduledoc """
  ARK (Archival Resource Key) scheme.

  See https://datatracker.ietf.org/doc/html/draft-kunze-ark-44
  """

  @behaviour IDUtils.Scheme

  @resolver "https://n2t.net/"

  @label "ark:"

  @betanumeric ~c"bcdfghjkmnpqrstvwxz0123456789"

  # Public API

  @doc """
  Builds a URI for the given ARK and NMA.

  ## Parameters

  * `ark` - The ARK to build a `t:URI.t/0` for.
  * `resolver` - The NMA resolver URL to use for building the URI.

  ## Examples

      iex> IDUtils.Schemes.ARK.build_uri("ark:/12148/btv1b8449691v/f29", "https://gallica.bnf.fr")
      {:ok, %URI{scheme: "https", host: "gallica.bnf.fr", path: "/ark:/12148/btv1b8449691v/f29", port: 443}}
  """
  def build_uri(ark, resolver) when is_binary(ark) and is_binary(resolver) do
    build_uri(String.trim_trailing(resolver, "/") <> "/" <> ark)
  end

  # Callbacks

  @doc """
  Check whether a string can be matched as an ARK.

  ## Examples

      iex> IDUtils.Schemes.ARK.match?("ark:12345/x6np1wh8k")
      true

      iex> IDUtils.Schemes.ARK.match?("https://gallica.bnf.fr/ark:/12148/btv1b8449691v/f29")
      true
  """
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string, :validate) do
      {:ok, _} -> true
      :error -> false
    end
  end

  @doc """
  Normalizes an ARK.

  ## Examples

      iex> IDUtils.Schemes.ARK.normalize("ark:/12345/x6np1wh8k")
      {:ok, "ark:12345/x6np1wh8k"}

      iex> IDUtils.Schemes.ARK.normalize("ark:12345/x6np1wh8k/ms/971863.pdf")
      {:ok, "ark:12345/x6np1wh8k/ms/971863.pdf"}

      iex> IDUtils.Schemes.ARK.normalize("https://gallica.bnf.fr/ark:/12148/bpt6k1")
      {:ok, "ark:12148/bpt6k1"}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string, :normalize) do
      {:ok, {naan, name}} -> {:ok, @label <> naan <> "/" <> name}
      {:ok, {naan, name, qualifier}} -> {:ok, @label <> naan <> "/" <> name <> "/" <> qualifier}
      :error -> {:error, :invalid_identifier}
    end
  end

  @doc """
  Builds a URI for the given ARK.

  For compact ARKs, the N2T resolver is used. If the ARK is passed as a URL string, it is parsed
  as-is.

  ## Examples

      iex> IDUtils.Schemes.ARK.build_uri("ark:12148/btv1b8449691v/f29")
      {:ok, %URI{scheme: "https", host: "n2t.net", path: "/ark:12148/btv1b8449691v/f29", port: 443}}

      iex> IDUtils.Schemes.ARK.build_uri("https://gallica.bnf.fr/ark:/12148/btv1b8449691v/f29")
      {:ok, %URI{scheme: "https", host: "gallica.bnf.fr", path: "/ark:/12148/btv1b8449691v/f29", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(ark) when is_binary(ark) do
    case URI.new(ark) do
      {:ok,
       %URI{
         fragment: nil,
         host: <<_, _::binary>>,
         query: nil,
         scheme: scheme
       } = uri}
      when scheme in ["http", "https"] ->
        {:ok, uri}

      _ ->
        URI.new(@resolver <> ark)
    end
  end

  # Private helpers

  defguardp is_ark_label(a, r, k) when a in [?a, ?A] and r in [?r, ?R] and k in [?k, ?K]

  defguardp is_betanumeric(c) when c in @betanumeric

  defguardp is_valid_byte(c)
            when c in ?a..?z or c in ?A..?Z or c in ?0..?9 or
                   c in [?=, ?~, ?*, ?+, ?@, ?_, ?$]

  defguardp is_separator(c) when c in [?., ?/]

  # discarded in normalization
  defguardp is_ignored_byte(c) when c in [?-]

  defguardp is_hex_digit(c) when c in ?0..?9 or c in ?a..?f or c in ?A..?F
  defguardp is_hex_group(a, b) when is_hex_digit(a) and is_hex_digit(b)

  defp parse("https://" <> _rest = url, mode), do: parse_ark_url(url, mode)
  defp parse("http://" <> _rest = url, mode), do: parse_ark_url(url, mode)
  defp parse(<<a, r, k, ":", rest::binary>>, mode) when is_ark_label(a, r, k), do: ark(rest, mode)
  defp parse(string, mode), do: parse_uri_path(string, mode)

  defp parse_ark_url(url_string, mode) do
    with {:ok, %URI{path: path} = uri} <- URI.new(url_string),
         :ok <- check_uri(uri, mode) do
      parse_uri_path(path, mode)
    else
      _ -> :error
    end
  end

  # normalization proceeds on a noisy url, validation doesn't
  defp check_uri(%URI{path: nil}, _), do: :error
  defp check_uri(%URI{} = _uri, :normalize), do: :ok
  defp check_uri(%URI{fragment: nil, host: <<_, _::binary>>, query: nil, userinfo: nil}, _), do: :ok
  defp check_uri(_uri, _validate), do: :error

  # find first occurence of `/ark:`, slice after
  defp parse_uri_path(path, mode) do
    case String.split(path, ["/ark:", "/ARK:", "/Ark:"], parts: 2) do
      [_before, rest] -> ark(rest, mode)
      [_no_match] -> :error
    end
  end

  # discard slash from legacy label form `ark:/`
  defp ark(<<?/, rest::binary>>, mode), do: naan(rest, <<>>, mode)
  defp ark(rest, mode), do: naan(rest, <<>>, mode)

  defp naan(<<c, rest::binary>>, acc, mode) when is_betanumeric(c) do
    naan(rest, <<acc::binary, c>>, mode)
  end

  # naan is five digits, other patterns are "reserved, subject to future definition"
  defp naan(<<?/, rest::binary>>, acc, mode) when byte_size(acc) == 5 do
    tail(rest, acc, <<>>, nil, mode)
  end

  defp naan(_, _, _), do: :error

  # combined matching rules for name and qualifier
  # `sep` is nil or the first pending structural byte
  defp tail(<<>>, naan, acc, _sep, _mode) do
    finish(naan, acc)
  end

  defp tail(<<??, _::binary>>, naan, acc, _sep, :normalize) do
    finish(naan, acc)
  end

  defp tail(<<?%, a, b, rest::binary>>, naan, acc, sep, mode) when is_hex_group(a, b) do
    tail(rest, naan, <<flush(acc, sep)::binary, ?%, upper(a), upper(b)>>, nil, mode)
  end

  defp tail(<<c, rest::binary>>, naan, acc, sep, mode) when is_ignored_byte(c) do
    tail(rest, naan, acc, sep, mode)
  end

  defp tail(<<c, rest::binary>>, naan, acc, sep, mode) when is_separator(c) do
    sep = if sep == nil and acc != <<>>, do: c, else: sep
    tail(rest, naan, acc, sep, mode)
  end

  defp tail(<<c, rest::binary>>, naan, acc, sep, mode) when is_valid_byte(c) do
    tail(rest, naan, <<flush(acc, sep)::binary, c>>, nil, mode)
  end

  defp tail(_, _, _, _, _), do: :error

  defp finish(_naan, <<>>), do: :error

  defp finish(naan, acc) do
    case :binary.split(acc, "/") do
      [name] -> {:ok, {naan, name}}
      [name, qualifier] -> {:ok, {naan, name, qualifier}}
    end
  end

  defp flush(acc, nil), do: acc
  defp flush(acc, sep), do: <<acc::binary, sep>>

  defp upper(c) when c in ?a..?f, do: c - 32
  defp upper(c), do: c
end
