# Disambiguation by suppression rules follows the approach of idutils' (https://github.com/
# inveniosoftware/idutils) SCHEME_FILTER, some individual rules are taken from it.
defmodule IDUtils.Scheme.Disambiguation do
  @moduledoc false
  # Rule-based disambiguation used in scheme detection

  alias IDUtils.Schemes.Handle
  alias IDUtils.Schemes.ISNI
  alias IDUtils.Schemes.RAID

  # matched scheme -> list of schemes to drop if matched scheme is present
  #
  # optionally as `{scheme, condition_fn}` to only drop a scheme when the condition is met.
  # the function receives the value for which the detection is run
  @suppression_rules %{
    url: [
      :issn,
      {:handle, &__MODULE__.no_handle_prefix?/1}
    ],
    isni: [
      :gnd,
      {:handle, &ISNI.prefix?/1}
    ],
    orcid: [
      :gnd
    ],
    issn: [
      :gnd
    ],
    ark: [
      :handle
    ],
    doi: [
      {:raid, &__MODULE__.no_raid_prefix?/1}
    ]
  }

  # Internal API

  @doc """
  Applies suppression rules to a list of schemes.

  The purpose of this function is twofold:

    * drop more generic matches from the list when a more specific match is available
    * ensure contradictory match results are definitively resolved (e.g., an ISSN can't also
      be a URL)
  """
  @spec apply([atom()], binary()) :: [atom()]
  def apply(schemes, value) do
    removed =
      for scheme <- schemes,
          rule <- Map.get(@suppression_rules, scheme, []),
          applies?(rule, value),
          do: target(rule)

    schemes -- removed
  end

  @doc false
  def no_handle_prefix?(value), do: not Handle.prefix?(value)

  @doc false
  def no_raid_prefix?(value), do: not RAID.prefix?(value)

  # Private helpers

  defp applies?({_target, condition}, value), do: condition.(value)
  defp applies?(_target, _value), do: true

  defp target({target, _condition}), do: target
  defp target(target), do: target
end
