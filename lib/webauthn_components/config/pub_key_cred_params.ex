defmodule WebauthnComponents.Config.PubKeyCredParams do
  @moduledoc """
  Struct used to specify the algorithms supported by the host application.

  ## Algorithms

  By default, `WebauthnComponents.Config.PublicKeyOptions` includes the algorithms suggested by MDN documentation:

  - `-8` EdDSA
  - `-7` ES256
  - `-257` RS256

  You may override the default list of `PubKeyCredParams` when creating the `PublicKeyOptions` struct.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#pubkeycredparams
  - https://www.iana.org/assignments/cose#algorithms
  """

  @type t :: %__MODULE__{
          alg: integer(),
          type: String.t()
        }

  @derive JSON.Encoder
  @derive Jason.Encoder
  @enforce_keys [:alg]
  defstruct [:alg, type: "public-key"]
end
