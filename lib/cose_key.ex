defmodule LiveShowy.Types.CoseKey do
  @moduledoc """
  Custom type for WebAuthn cose keys.
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

  def dump(value), do: {:ok, value}
end
