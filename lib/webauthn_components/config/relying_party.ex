defmodule WebauthnComponents.Config.RelyingParty do
  @moduledoc """
  Struct used to identify the application associated with a credential.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#rp
  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }

  @derive JSON.Encoder
  @derive Jason.Encoder
  @enforce_keys [:name]
  defstruct [:id, :name]
end
