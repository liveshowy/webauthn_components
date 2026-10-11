defmodule WebauthnComponents.Config.User do
  @moduledoc """
  Struct used to identify the user associated with a credential.

  ## User ID

  The `:id` field may contain a string or binary value which will be used to identify the user in future authentication requests. This field is typically not displayed to the user in authentication prompts. The value of this field is passed as the `userHandle` value in the client-side WebAuthn API when registering a new credential.

  While a username or email _could_ be used here, the credential's `userHandle` value cannot be modified. This means a change to the email or username in the server would result in an unusable credential.

  ## Name & Display Name

  The `:name` and `:display_name` fields represent data presented to the user during authentication. These values help the user to distinguish between multiple accounts if more than one credential is registered to a relying party.

  These fields may use the same value or distinct values depending on the design of the host application.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#user
  """

  @type t :: %__MODULE__{
          display_name: String.t(),
          id: String.t() | binary(),
          name: String.t()
        }

  @enforce_keys [:id, :name, :display_name]
  defstruct [:id, :name, :display_name]

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:id, &Base.url_encode64(&1, padding: false))
      |> Map.put(:displayName, struct.display_name)
      |> Map.drop([:display_name])
      |> Jason.Encode.map(opts)
    end
  end

  defimpl JSON.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:id, &Base.url_encode64(&1, padding: false))
      |> Map.put(:displayName, struct.display_name)
      |> Map.drop([:display_name])
      |> JSON.encode!(opts)
    end
  end
end
