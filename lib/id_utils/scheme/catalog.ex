defmodule IDUtils.Scheme.Catalog do
  @moduledoc """
  Catalog of identifier schemes supported by IDUtils.
  """

  # List order is intentional, determines scheme detection
  @schemes [
    doi: IDUtils.Schemes.DOI,
    ark: IDUtils.Schemes.ARK,
    raid: IDUtils.Schemes.RAID,
    handle: IDUtils.Schemes.Handle,
    urn: IDUtils.Schemes.URN,
    issn: IDUtils.Schemes.ISSN,
    orcid: IDUtils.Schemes.ORCID,
    isni: IDUtils.Schemes.ISNI,
    gnd: IDUtils.Schemes.GND,
    ror: IDUtils.Schemes.ROR,
    openalex: IDUtils.Schemes.OpenAlex,
    url: IDUtils.Schemes.URL
  ]

  @scheme_names @schemes
                |> Keyword.keys()
                |> Enum.sort()

  @typedoc """
  A keyword list of scheme modules.
  """
  @type t :: [{atom(), module()}]

  # Public API

  @doc """
  Lists the names of all built-in supported schemes.
  """
  @spec list() :: [atom()]
  def list, do: @scheme_names

  @doc """
  Returns the ordered scheme mapping.

  Note: The order of the schemes is important for detecting schemes correctly. If you work with
  this data structure, make sure to preserve its order.
  """
  @spec all() :: t()
  def all, do: @schemes

  @doc """
  Extends the built-in scheme catalog with custom schemes.

  This function will simply append custom schemes to the built-in catalog. It raises an
  `ArgumentError` if a custom scheme key already exists in the built-in catalog. For advanced
  customization, use `all/0` and modify the resulting `t:t/0` directly.

  ## Parameters

    * `custom_schemes` - A list of custom schemes to append to the built-in list.
  """
  @spec extend(t()) :: t()
  def extend(custom_schemes) when is_list(custom_schemes) do
    case Keyword.take(@schemes, Keyword.keys(custom_schemes)) do
      [] ->
        @schemes ++ custom_schemes

      conflicts ->
        names =
          conflicts
          |> Keyword.keys()
          |> Enum.map_join(", ", &inspect/1)

        raise ArgumentError, "schemes already exist in the built-in catalog: #{names}"
    end
  end

  @doc """
  Returns the module associated with a scheme name.

  ## Parameters

    * `scheme_name` - The name of the scheme to look up.
    * `scheme_list` - An optional list of schemes (defaults to the built-in list).
  """
  @spec module_for(atom(), [] | t()) :: {:ok, module()} | {:error, :unknown_scheme}
  def module_for(scheme_name, scheme_list \\ all()) do
    Enum.find_value(scheme_list, {:error, :unknown_scheme}, fn
      {^scheme_name, module} -> {:ok, module}
      _ -> nil
    end)
  end

  @doc """
  Returns the name associated with a scheme module.

  ## Parameters

    * `scheme_module` - The scheme module to look up.
    * `scheme_list` - An optional list of schemes (defaults to the built-in list).
  """
  @spec name_for(module(), [] | t()) :: {:ok, atom()} | {:error, :unknown_scheme}
  def name_for(scheme_module, scheme_list \\ all()) do
    Enum.find_value(scheme_list, {:error, :unknown_scheme}, fn
      {name, ^scheme_module} -> {:ok, name}
      _ -> nil
    end)
  end
end
