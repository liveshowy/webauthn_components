import Config

config :phoenix, :json_library, Jason

config :webauthn_components, TestEndpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "m4lmm6l5OUJaDLJwNW63wzAUEw74WTvTH82FU8UBUig8UF4dK1OoOqbILAImU2E3",
  server: false,
  live_view: [signing_salt: "ZSDZGW0RqaKYeQE1y87NKQ7L+1Ho3gqV"]
