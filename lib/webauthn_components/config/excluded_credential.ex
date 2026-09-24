defmodule WebauthnComponents.Config.ExcludedCredential do
  @moduledoc """
  Struct representing credentials which are already associated with the user, which should not be duplicated.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#excludecredentials
  """

  @type t :: %__MODULE__{
          id: String.t() | binary(),
          transports: [transport()],
          type: String.t()
        }

  @type transport :: :ble | :hybrid | :internal | :nfc | :usb

  @derive JSON.Encoder
  @derive Jason.Encoder
  @enforce_keys [:id]
  defstruct [:id, :transports, type: "public-key"]
end
