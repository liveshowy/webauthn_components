# WebAuthnComponents

A drop-in LiveComponent for password-less authentication.

### 🚨 Status 🚨

This package is a **work in progress**, and it is in early alpha status. Feel free to experiment with this package and contribute feedback through [GitHub discussions](https://github.com/liveshowy/webauthn_components/discussions).

Please **do not use WebAuthnComponents in a production environment** until it has completed _beta_ testing.

## Roadmap

View the planned work for this repo in the public [WebAuthnComponents v1](https://github.com/orgs/liveshowy/projects/3/views/1) project on GitHub.

## Quick Start

During the beta phase, generators will be added to streamline initial setup, including running migrations, generating related modules, etc. Steps marked `(TODO)` need additional documentation, and some may be streamlined by Mix tasks during the beta phase.

1. Add Mix dependency
1. Add `WebAuthn` hook to `app.js`
1. Run Mix task to create `user_keys` schema & migration
   - `mix phx.gen.context --binary-id Authentication UserKey user_keys key_id:binary label last_used:utc_datetime public_key:binary user_id:references:users`
1. Update `UserKey` schema (TODO)
   - Add default value to the `label` field
   - Update the `public_key` field to use `WebAuthnComponents.CoseKey` as its type
   - Add `new_changeset/2` & `update_changeset/2` (TODO)
1. Run Mix task to create `user_tokens` schema & migration
   - `mix phx.gen.context --binary-id Authentication UserToken user_tokens user_id:references:users token:binary context`
1. Update `UserToken` schema
   - Update the `context` field to use `Ecto.Enum` as its type with `values: [:session, :device_code]` and `default: :session`
   - Replace `user_id` field with `belongs_to` `User` association
   - Add `foreign_key_constraint` `:user_id`
   - Add token helper functions (TODO)
1. Update `User` and/or relevant schemas to include keys association (TODO)
1. Run Mix task to add component config (TODO)

### Installation

Add `webauthn_components` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:webauthn_components, "~> 0.1.0"}
  ]
end
```

### Usage

See `WebAuthnComponents` for detailed usage instructions.

## WebAuthn & Passkeys

> The Web Authentication API is an extension of the Credential Management API that enables strong authentication with public key cryptography, enabling passwordless authentication and/or secure second-factor authentication without SMS texts.
>
> https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API

> A passkey is a FIDO login credential, tied to an origin (website or application) and a physical device. Passkeys allow users to authenticate without having to enter a username, password, or provide any additional authentication factor. This technology aims to replace passwords as the primary authentication mechanism.
>
> https://developers.google.com/identity/fido

Passkeys are essentially a standard to sync WebAuthn credentials with cloud platforms like [iCloud Keychain](https://developer.apple.com/passkeys/), [Android](https://developers.google.com/identity/fido), [1Password](https://blog.1password.com/1password-is-joining-the-fido-alliance/), with more to come.

### Benefits

There are many benefits to users and application maintainers when passwords are decommissioned.

- Eliminates password reuse by users.
- Mitigates credential stuffing attacks by hackers.
- Eliminates phishing attacks by hackers.

For users on a device with Passkey support, WebAuthn credentials may be stored in the cloud. This allows the user to authenticate from other cloud-connected devices without registering each device individually.

### Known Issues

While WebAuthn provides an API for improved authentication security, there are a few limitations to consider before adopting this component.

- As of 2022, Passkeys are not universally supported.
- If a user registers or authenticates on a device without Passkey support, the generated key pair will not be synced, and each device must be registered in order to access an account.
- Cloud-synced credentials are only accessible to devices authenticated to the cloud account.
  - For example, a credential saved to iCloud Keychain will not be synced automatically to Android's credential manager.

## Browser Support

The WebAuthn API has broad support across the most common modern browsers.

https://caniuse.com/?search=webauthn

## Additional Resources

- https://webauthn.guide/
- https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API
- https://fidoalliance.org/fido2-2/fido2-web-authentication-webauthn/
- https://www.w3.org/TR/webauthn-2/
