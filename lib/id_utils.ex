defmodule IDUtils do
  @moduledoc """
  Utilities for working with persistent identifiers used in scholarly communication.
  """

  alias IDUtils.Scheme.Catalog
  alias IDUtils.Scheme.Disambiguation

  # Public API

  @doc """
  Normalizes a value according to the given identifier scheme.

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes. Defaults to all built-in schemes.
  """
  @spec normalize(String.t(), atom(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def normalize(<<_::utf8, _::binary>> = value, scheme, opts \\ []) do
    catalog = fetch_catalog!(opts)

    case Catalog.module_for(scheme, catalog) do
      {:ok, module} -> module.normalize(value)
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Detects identifier schemes for a given value.

  The resulting list of scheme names is ordered by specificity, i.e. the best match is first.

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes to check against. Defaults to all
      built-in schemes.
  """
  @spec detect_schemes(String.t(), keyword()) :: {:ok, [atom()]}
  def detect_schemes(<<_::utf8, _::binary>> = value, opts \\ []) do
    catalog = fetch_catalog!(opts)

    matches =
      for {scheme, module} <- catalog,
          module.match?(value),
          do: scheme

    {:ok, Disambiguation.apply(matches, value)}
  end

  @doc """
  Converts a canonical form of an identifier to a URI.

  Note that not all schemes have a URI representation.

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes. Defaults to all built-in schemes.
  """
  @spec to_uri(String.t(), atom(), keyword()) :: {:ok, URI.t()} | {:error, :not_supported | term()}
  def to_uri(<<_::utf8, _::binary>> = value, scheme, opts \\ []) do
    opts
    |> fetch_catalog!()
    |> build_uri(scheme, value)
  end

  @doc """
  Converts a canonical form of an identifier to a URL string.

  Note that not all schemes have a URL representation.

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes. Defaults to all built-in schemes.
  """
  @spec to_url(String.t(), atom(), keyword()) :: {:ok, String.t()} | {:error, :not_supported | term()}
  def to_url(<<_::utf8, _::binary>> = value, scheme, opts \\ []) do
    case opts
         |> fetch_catalog!()
         |> build_uri(scheme, value) do
      {:ok, uri} -> {:ok, URI.to_string(uri)}
      {:error, _reason} = error -> error
    end
  end

  # Private helpers

  defp fetch_catalog!(opts) do
    opts
    |> Keyword.validate!(catalog: Catalog.all())
    |> Keyword.fetch!(:catalog)
  end

  defp build_uri(catalog, scheme, value) do
    with {:ok, module_name} <- Catalog.module_for(scheme, catalog),
         {:module, module} <- Code.ensure_loaded(module_name),
         :ok <-
           module
           |> function_exported?(:build_uri, 1)
           |> to_result() do
      module.build_uri(value)
    end
  end

  defp to_result(true), do: :ok
  defp to_result(false), do: {:error, :not_supported}
end
