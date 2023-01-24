defmodule Factory do
  @moduledoc false

  def build(:registration_challenge) do
    Wax.new_registration_challenge(
      attestation: "none",
      origin: "http://localhost",
      rp_id: :auto,
      trusted_attestation_types: [:none, :basic]
    )
  end

  def build(:authentication_challenge) do
    Wax.new_authentication_challenge(
      origin: "http://localhost",
      rp_id: :auto,
      allow_credentials: []
    )
  end
end
