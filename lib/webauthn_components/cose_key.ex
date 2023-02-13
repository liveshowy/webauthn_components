defmodule WebauthnComponents.CoseKey do
  @moduledoc """
  Custom `Ecto.Type` for WebAuthn cose keys.

  Use this type for the `:public_key` field in an Ecto schema.

  ## Example

  ```elixir
  defmodule MyApp.Authentication.UserKey do
    use Ecto.Schema
    import Ecto.Changeset
    alias MyApp.Accounts.User
    alias WebauthnComponents.CoseKey

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @derive {Jason.Encoder, only: [:key_id, :public_key, :label, :last_used]}
    schema "user_keys" do
      field :label, :string, default: "default"
      field :key_id, :binary
      field :user_handle, :binary
      field :public_key, CoseKey
      belongs_to :user, User
      field :last_used, :utc_datetime

      timestamps()
    end

    ...
  end
  ```
  """
  use Ecto.Type

  def type, do: :binary

  def cast(value) when is_map(value) do
    try do
      {:ok, CBOR.encode(value)}
    rescue
      Protocol.UndefinedError -> :error
    end
  end

  def cast(value) when is_binary(value) do
    case CBOR.decode(value) do
      {:ok, _decoded_value, ""} -> value
      {:error, _error} -> :error
    end
  end

  def cast(_), do: :error

  def load(data) when is_binary(data) do
    case CBOR.decode(data) do
      {:ok, cose_key, ""} ->
        {:ok, cose_key}

      _other ->
        :error
    end
  end

  def dump(value) when is_map(value) do
    {:ok, CBOR.encode(value)}
  end

  def dump(value) when is_binary(value) do
    case CBOR.decode(value) do
      {:ok, _decoded_value, ""} -> {:ok, value}
      {:error, _error} -> :error
    end
  end

  def dump(value), do: {:ok, value}
end
