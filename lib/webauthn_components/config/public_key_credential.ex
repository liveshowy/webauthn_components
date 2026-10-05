defmodule WebauthnComponents.Config.PublicKeyCredential do
  @moduledoc false
  alias WebauthnComponents.Config.AuthenticatorAssertionResponse

  @type t :: %__MODULE__{
          authenticator_attachment: String.t(),
          id: binary(),
          response: AuthenticatorAssertionResponse.t(),
          type: String.t()
        }
  @enforce_keys [:authenticator_attachment, :id, :response, :type]
  defstruct [:authenticator_attachment, :id, :response, :type]
end
