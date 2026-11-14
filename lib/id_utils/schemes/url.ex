defmodule IDUtils.Schemes.URL do
  @moduledoc """
  URL (Uniform Resource Locator) scheme.

  For the purposes of this library, an identifier URL will be matched if it has a scheme and a
  host. While `mailto:test@example.com` is a perfectly valid URL, it is not considered a "valid"
  identifier URL here.

  > #### Parsing {: .info}
  >
  > Elixir's `URI` module implements [RFC 3986](https://tools.ietf.org/html/rfc3986), not the
  > [WHATWG URL standard](https://url.spec.whatwg.org) followed by browsers, which in general
  > tends to be more lenient around some edge cases (e.g., unencoded square brackets in query
  > strings, backslashes used as path separators). These should generally not be relevant in an
  > identifier context, but be aware this module might reject URLs that are accepted by browsers.
  """

  @behaviour IDUtils.Scheme

  # Callbacks

  @doc """
  Checks whether a string is a URL.

  ## Examples

      iex> IDUtils.Schemes.URL.match?("https://gallica.bnf.fr/f29")
      true

      iex> IDUtils.Schemes.URL.match?("mailto:test@example.com")
      false
  """
  # TODO: IDNA
  @impl IDUtils.Scheme
  def match?(string) when is_binary(string) do
    case parse(string) do
      {:ok, %URI{}} -> true
      {:error, _reason} -> false
    end
  end

  @doc """
  Normalizes a URL.

  ## Examples

      iex> IDUtils.Schemes.URL.normalize("https://example.com/12148")
      {:ok, "https://example.com/12148"}

      iex> IDUtils.Schemes.URL.normalize("https://example.com:443")
      {:ok, "https://example.com/"}

      iex> IDUtils.Schemes.URL.normalize("example.com/x6np1wh8k")
      {:error, :invalid_identifier}
  """
  @impl IDUtils.Scheme
  def normalize(string) when is_binary(string) do
    case parse(string) do
      {:ok, %URI{}} -> normalize_uri_string(string)
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Builds a URI for the given URL string.

  ## Examples

      iex> IDUtils.Schemes.URL.build_uri("https://gallica.bnf.fr/f29")
      {:ok, %URI{scheme: "https", host: "gallica.bnf.fr", path: "/f29", port: 443}}
  """
  @impl IDUtils.Scheme
  def build_uri(string) when is_binary(string) do
    URI.new(string)
  end

  # Private helpers

  defp parse(string) do
    case URI.new(string) do
      {:ok, %URI{host: host}} when host in [nil, ""] -> {:error, :invalid_identifier}
      {:ok, %URI{scheme: nil}} -> {:error, :invalid_identifier}
      {:ok, %URI{} = uri} -> {:ok, uri}
      _ -> {:error, :invalid_identifier}
    end
  end

  defp normalize_uri_string(string) do
    case :uri_string.normalize(string) do
      {:error, _reason, _debug} -> {:error, :invalid_identifier}
      normalized -> {:ok, normalized}
    end
  end
end
