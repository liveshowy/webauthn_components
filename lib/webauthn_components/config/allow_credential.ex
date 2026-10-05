defmodule WebauthnComponents.Config.AllowCredential do
  @moduledoc """
  Struct representing a credential registered to a user which may be used for authentication.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialRequestOptions#allowcredentials
  """
  @type t :: %__MODULE__{
          id: String.t() | binary(),
          transports: [String.t()],
          type: String.t()
        }

  @enforce_keys [:id]
  @derive JSON.Encoder
  @derive Jason.Encoder
  defstruct [:id, transports: [], type: "public-key"]
end
