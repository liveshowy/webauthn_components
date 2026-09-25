defmodule WebauthnComponents.Config.PubKeyCredParams do
  @moduledoc """
  Struct used to specify the algorithms supported by the host application.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#pubkeycredparams
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
