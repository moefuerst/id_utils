defmodule IDUtils.Scheme do
  @moduledoc """
  Defines the behavior of an identifier scheme.
  """

  @doc """
  Returns whether the given input is an identifier according to the scheme.
  """
  @callback match?(input) :: boolean()
            when input: binary()

  @doc """
  Normalizes the input to the scheme's canonical form.
  """
  @callback normalize(input) :: {:ok, canonical} | {:error, :invalid_identifier}
            when input: binary(), canonical: binary()

  @doc """
  Builds a URI from the canonical form.
  """
  @callback build_uri(canonical) :: {:ok, URI.t()} | {:error, reason}
            when canonical: binary(), reason: term()

  @optional_callbacks build_uri: 1
end
