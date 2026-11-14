defmodule IDUtils do
  @moduledoc """
  Utilities for working with persistent identifiers used in scholarly communication.
  """

  alias IDUtils.Scheme.Catalog
  alias IDUtils.Scheme.Disambiguation

  # Public API

  @doc """
  Detects identifier schemes for a given value.

  The resulting list of scheme names is ordered by specificity, i.e. the best match is first.

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes to check against. Defaults to all
      built-in schemes.

  ## Examples

      iex> IDUtils.detect_schemes("0000000218250097")
      [:orcid, :isni]

      iex> IDUtils.detect_schemes("urn:doi:10.1093/annonc/mdz260.023")
      [:doi, :handle, :urn]

      iex> IDUtils.detect_schemes("not-a-pid")
      []
  """
  @spec detect_schemes(String.t(), keyword()) :: [atom()]
  def detect_schemes(<<_::utf8, _::binary>> = value, opts \\ []) do
    catalog = fetch_catalog!(opts)

    matches =
      for {scheme, module} <- catalog,
          module.match?(value),
          do: scheme

    Disambiguation.apply(matches, value)
  end

  @doc """
  Returns whether the given value matches the given identifier scheme.

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes. Defaults to all built-in schemes.

  ## Examples

      iex> IDUtils.match?("000000029079593X", :orcid)
      true
  """
  @spec match?(String.t(), atom(), keyword()) :: boolean()
  def match?(<<_::utf8, _::binary>> = value, scheme, opts \\ []) do
    catalog = fetch_catalog!(opts)

    case Catalog.module_for(scheme, catalog) do
      {:ok, module} -> module.match?(value)
      {:error, _reason} -> false
    end
  end

  @doc """
  Normalizes a value according to the given identifier scheme.

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes. Defaults to all built-in schemes.

  ## Examples

      iex> IDUtils.normalize("000000029079593X", :orcid)
      {:ok, "0000-0002-9079-593X"}

      iex> IDUtils.normalize("http://www.lagrandecollecte.fr/ark:/12148/btv1b10100333n.image", :ark)
      {:ok, "ark:12148/btv1b10100333n.image"}
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
  Converts a canonical form of an identifier to a URI.

  Note that not all schemes have a URI representation.

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes. Defaults to all built-in schemes.

  ## Examples

      iex> IDUtils.to_uri("10.5281/zenodo.15293455", :doi)
      {:ok, %URI{scheme: "https", host: "doi.org", path: "/10.5281/zenodo.15293455", port: 443}}
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

  ## Examples

      iex> IDUtils.to_url("0000000121480099", :isni)
      {:ok, "https://isni.org/isni/0000000121480099"}
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
