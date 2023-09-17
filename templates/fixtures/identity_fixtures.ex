defmodule <%= inspect @app_pascal_case %>.IdentityFixtures do
  @moduledoc false
  alias <%= inspect @app_pascal_case %>.Identity
  alias WebauthnComponents.WebauthnUser

  def random_integer, do: System.unique_integer([:positive, :monotonic])
  def unique_email, do: "user#{random_integer()}@example.com"

  def encoded_id(byte_length \\ 64) do
    byte_length
    |> random_bytes()
    |> Base.encode64(padding: false)
  end

  def random_bytes(byte_length \\ 64), do: :crypto.strong_rand_bytes(byte_length)

  def valid_user_attrs(attrs \\ []) do
    Enum.into(attrs, %{
      email: unique_email()
    })
  end

  def user_fixture(attrs \\ []) do
    {:ok, user} =
      attrs
      |> valid_user_attrs()
      |> Identity.create()

    user
  end

  # WebauthnComponents Structs

  def webauthn_user(attrs \\ []) do
    email = unique_email()

    Enum.into(
      attrs,
      %WebauthnUser{
        id: encoded_id(),
        name: email,
        display_name: email
      }
    )
  end

  def user_key_attrs(attrs \\ []) do
    Enum.into(
      attrs,
      %{
        key_id: random_bytes(),
        public_key: cose_key()
      }
    )
  end

  # Wax Structs

  @default_origin "http://localhost"

  def registration_challenge(attrs \\ []) do
    attrs =
      Enum.into(
        attrs,
        attestation: "none",
        origin: @default_origin,
        rp_id: :auto,
        trusted_attestation_types: [:none, :basic]
      )

    Wax.new_registration_challenge(attrs)
  end

  def authentication_challenge(attrs) do
    attrs =
      Enum.into(attrs,
        origin: @default_origin,
        rp_id: :auto,
        allow_credentials: [],
        user_verification: "preferred"
      )

    Wax.new_authentication_challenge(attrs)
  end

  def cose_key do
    %{
      -3 =>
        <<182, 81, 183, 218, 92, 107, 106, 120, 60, 51, 75, 104, 141, 130, 119, 232, 34, 245, 84,
          203, 246, 165, 148, 179, 169, 31, 205, 126, 241, 188, 241, 176>>,
      -2 =>
        <<89, 29, 193, 225, 4, 234, 101, 162, 32, 6, 15, 14, 130, 179, 223, 207, 53, 2, 134, 184,
          178, 127, 51, 145, 57, 180, 104, 242, 138, 96, 27, 221>>,
      -1 => 1,
      1 => 2,
      3 => -7
    }
  end
end
