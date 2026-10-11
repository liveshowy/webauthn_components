defmodule WebauthnComponents.ExcludedCredential do
  @moduledoc """
  Struct representing credentials which are already associated with the user, which should not be duplicated.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#excludecredentials
  """

  @type t :: %__MODULE__{
          id: binary(),
          transports: [transport()],
          type: String.t()
        }

  @type transport :: :ble | :hybrid | :internal | :nfc | :usb

  @enforce_keys [:id]
  defstruct [:id, transports: [], type: "public-key"]

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:id, &Base.url_encode64(&1, padding: false))
      |> Jason.Encode.map(opts)
    end
  end

  defimpl JSON.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:id, &Base.url_encode64(&1, padding: false))
      |> JSON.encode!(opts)
    end
  end
end
