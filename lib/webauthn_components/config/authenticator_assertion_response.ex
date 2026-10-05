defmodule WebauthnComponents.Config.AuthenticatorAssertionResponse do
  @moduledoc false
  @type t :: %__MODULE__{
          authenticator_data: binary(),
          client_data_json: String.t(),
          signature: binary(),
          user_handle: String.t() | binary()
        }
  @enforce_keys [:authenticator_data, :client_data_json, :signature, :user_handle]
  defstruct [:authenticator_data, :client_data_json, :signature, :user_handle]
end
