defmodule WebauthnComponents.FindUser do
  @moduledoc """
  Struct used to find a user.

  See `WebauthnComponents.AuthenticationComponent` for usage documentation.
  """

  @type t :: %__MODULE__{
          user_handle: String.t() | binary()
        }

  @enforce_keys [:user_handle]
  defstruct [:user_handle]
end
