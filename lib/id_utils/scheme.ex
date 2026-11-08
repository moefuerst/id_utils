defmodule IDUtils.Scheme do
  @moduledoc """
  Defines the behavior of an identifier scheme.
  """

  @doc """
  Returns whether the given input is an identifier according to the scheme.

  Matching *may* be lenient by design: noisy input (e.g., a query string in an URL-representation
  of an identifier) matches. It is assumed that the output of `c:normalize/1` is always used for
  storage and comparison.
  """
  @callback match?(input) :: boolean()
            when input: binary()

  @doc """
  Normalizes the identifier to the scheme's canonical form.

  Implementations expect the input to be an identifier that conforms to the scheme. They are not
  required to guarantee rejection of input that is not a valid identifier.
  """
  @callback normalize(identifier) :: {:ok, canonical} | {:error, reason}
            when identifier: binary(), canonical: binary(), reason: term()

  @doc """
  Builds a URI from the canonical form.

  Implementations expect the input to be an identifier in its canonical form. Not all schemes have
  a URI representation, this callback is only implemented by schemes that support it.
  """
  @callback build_uri(canonical) :: {:ok, URI.t()} | {:error, reason}
            when canonical: binary(), reason: term()

  @optional_callbacks build_uri: 1
end
