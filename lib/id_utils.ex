defmodule IDUtils do
  @moduledoc """
  Utilities for working with persistent identifiers used in scholarly communication.

  IDUtils is composed of

    * `IDUtils` - the high-level API (this module).
    * Scheme modules - modules that implement the `IDUtils.Scheme` behaviour, and (depending on
      the scheme) expose additional functionality specific to a persistend identifier scheme.
    * `IDUtils.Scheme.Catalog` - a module for managing the catalog of schemes, which you can
      extend with your own custom schemes.


  ## Examples

  Detect if a string matches any persistent identifier schemes:

      iex> IDUtils.detect_schemes("0000000218250097")
      [:orcid, :isni]

  Or a specific scheme:

      iex> IDUtils.matches_scheme?("0000000218250097", :orcid)
      true

  Normalize it for comparison and storage:

      iex> IDUtils.normalize("0000000218250097", :orcid)
      {:ok, "0000-0002-1825-0097"}

  Transform it to a landing page `t:URI.t/0` or URL string:

      iex> IDUtils.to_uri("0000-0002-1825-0097", :orcid)
      {:ok, %URI{scheme: "https", host: "orcid.org", path: "/0000-0002-1825-0097", port: 443}}

      iex> IDUtils.to_url("0000-0002-1825-0097", :orcid)
      {:ok, "https://orcid.org/0000-0002-1825-0097"}

  All functions in this module expect a non-empty `t:String.t/0`. If you work with boundary input,
  validate and normalize it first, for example with `String.valid?/1` and `String.normalize/2`.

  ### Scheme detection

  As you can see from the example above, if a string matches several scheme specifications,
  `detect_schemes/1` returns them as a list where the order is meaningful:

  ORCID’s format is compatible with ISNI, and ORCIDs are frequently matched into corresponding
  ISNI records. However, IDUtils could establish that the given value is within the two reserved
  numeric blocks within the ISNI range dedicated to ORCID-issued identifiers, so `:orcid` is
  returned before `:isni` in the result.

  Detection will return matches in descending order of relevance, with the best/most specific
  match first. Naturally, "best" is somewhat opinionated for some combinations of input and
  schemes. For example, IDUtils assumes that the information that this string contains a DOI is,
  in a practical sense, more important than the fact that it is given in a URN format:

      iex> IDUtils.detect_schemes("urn:doi:10.1093/annonc/mdz260.023")
      [:doi, :handle, :urn]

  In particular the `:urn` and `:url` schemes are considered more "generic" and will often be at
  the end of a result. They are most useful when a specific shape of the identifier matters in
  your use case. Consider that the following inputs:

      iex> IDUtils.detect_schemes("ark:/12148/bpt6k103110n")
      [:ark]

      iex> IDUtils.detect_schemes("https://gallica.bnf.fr/ark:/12148/bpt6k103110n")
      [:ark, :url]

  normalize to the same compact ARK:

      iex> IDUtils.normalize("ark:/12148/bpt6k103110n", :ark)
      {:ok, "ark:12148/bpt6k103110n"}

      iex> IDUtils.normalize("https://gallica.bnf.fr/ark:/12148/bpt6k103110n", :ark)
      {:ok, "ark:12148/bpt6k103110n"}

  Building an URL string from the compact ARK will use the `n2t.net` resolver, which might not
  be what you want (see the `IDUtils.Schemes.ARK` module):

      iex> IDUtils.to_url("ark:12148/bpt6k103110n", :ark)
      {:ok, "https://n2t.net/ark:12148/bpt6k103110n"}

  > #### Valid scheme, not valid identifier {: .info}
  > Matching will only detect if an input matches an identifier *scheme,* not if it is a *valid*
  > identifier that actually has been issued.

  Note that some schemes are very generic and will be matched on many inputs:

      iex> IDUtils.detect_schemes("hello /world")
      [:handle]

  ### Customize schemes

  Functions in this module take a `:catalog` option. This allows you to remove schemes, replace
  implementations, change matching order or extend the catalog with custom schemes.

  For example, restrict the set of schemes to check against:

      iex> IDUtils.detect_schemes("10.1093/annonc/mdz260.023")
      [:doi, :handle]

      iex> my_catalog = IDUtils.Scheme.Catalog.all() |> Keyword.delete(:handle)
      iex> IDUtils.detect_schemes("10.1093/annonc/mdz260.023", catalog: my_catalog)
      [:doi]

  Extend the built-in catalog with modules that implement the `IDUtils.Scheme` behaviour:

      iex> defmodule MyCustomScheme do
      ...>   @impl IDUtils.Scheme
      ...>   def match?(_), do: true
      ...> end
      iex> my_catalog = [custom: MyCustomScheme] |> IDUtils.Scheme.Catalog.extend()
      iex> IDUtils.detect_schemes("10.1093/annonc/mdz260.023", catalog: my_catalog)
      [:doi, :handle, :custom]
  """

  alias IDUtils.Scheme.Catalog
  alias IDUtils.Scheme.Disambiguation

  # Public API

  @doc """
  Detects identifier schemes for a given value.

  The resulting list of scheme names is ordered, i.e. the "best" match is first (see module
  documentation).

  ## Options

    * `:catalog` - A `t:IDUtils.Scheme.Catalog.t/0` of schemes to check against. Defaults to all
      built-in schemes.

  ## Examples

      iex> IDUtils.detect_schemes("00a8p0m24")
      [:ror]

      iex> IDUtils.detect_schemes("https://gallica.bnf.fr/ark:/12148/bpt6k103110n")
      [:ark, :url]

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

      iex> IDUtils.matches_scheme?("000000029079593X", :orcid)
      true
  """
  @spec matches_scheme?(String.t(), atom(), keyword()) :: boolean()
  def matches_scheme?(<<_::utf8, _::binary>> = value, scheme, opts \\ []) do
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
