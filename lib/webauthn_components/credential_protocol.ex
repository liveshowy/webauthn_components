defprotocol WebauthnComponents.CredentialProtocol do
  @moduledoc """
  Protocol for retrieving common fields from public key credential structs.

  This protocol is used when a list of credentials is passed to `WebauthnComponents.AuthenticationComponent.update/2` to extract the fields required to validate a pending authentication request.

  For convenience, a default implementation is provided to pattern match on `:id` and `:public_key` fields from any struct or map.

  ## Custom Implementation

  If your public key credential schema/struct uses alternate field names, you may define a custom implementation.
  The following example schema uses a slightly different naming convention for its fields, so a custom implementation is defined:

  ```
  defmodule MyApp.Identity.PublicKeyCredential do
    use Ecto.Schema
    alias MyApp.Identity.User

    @primary_key {:key_id, :binary, autogenerate: false}
    schema "public_key_credentials" do
      field :pub_key, WebauthnComponents.CoseKey
      field :label, :string, default: "Default"
      belongs_to :user, User
      timestamps()
    end

    defimpl WebauthnComponents.CredentialProtocol do
      def id(%{key_id: key_id}), do: key_id
      def public_key(%{pub_key: pub_key}), do: pub_key
    end
  end
  ```
  """
  @fallback_to_any true
  def id(credential)
  def public_key(credential)
end

defimpl WebauthnComponents.CredentialProtocol, for: Any do
  def id(%{id: id}), do: id
  def public_key(%{public_key: public_key}), do: public_key
end
