defmodule WebauthnComponents.WebauthnUser do
  @moduledoc """
  Struct representing required fields used by the WebAuthn API.
  """
  @enforce_keys [:id, :name, :display_name]
  defstruct [:id, :name, :display_name]

  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          display_name: String.t()
        }
end
