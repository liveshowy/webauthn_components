# WebauthnComponents

Passkey authentication for Phoenix LiveView applications.


## Scope

WebauthnComponents wraps the client-server coordination of the WebAuthn ceremonies so that implementers can focus on the data model, business logic, and user experience. It provides:

- `WebauthnComponents.ClientCapabilitiesComponent` — detect Passkey support in the browser.
- `WebauthnComponents.RegistrationComponent` — create a new credential.
- `WebauthnComponents.AuthenticationComponent` — authenticate with an existing credential.

Credential persistence, user lookup, and session management are the host application's responsibility. Persist at least the credential id, public key, and a reference to the user, then use them to verify future visits. See `WebauthnComponents.RegistrationComponent` and `WebauthnComponents.AuthenticationComponent` for details.

> The `wac.install` Mix task and the bundled code generators were removed in v0.10. Implementers are free to follow CRUD, Event Sourcing, or other patterns for user and credential management.

## Installation

Add the dependency to your `mix.exs`:

```elixir
# my_app/mix.exs
def deps do
  [
    ...
    {:webauthn_components, "~> 0.11"}
  ]
end
```

Install and compile the dependency:

```shell
mix deps.get
mix compile
```

Register the package's JavaScript hooks with your `LiveSocket`. They are exported from `priv/static/main.ts`:

- `ClientCapabilitiesHook`
- `RegistrationHook`
- `AuthenticationHook`

Each component sets a matching `phx-hook` attribute, so the hook names must be registered globally with `LiveSocket`.

## Usage

The components are designed to support a variety of user-facing flows: separate registration and authentication pages, a consolidated page, or features rendered in a global navbar. Credential management commonly lives on a user settings page.

See the component module documentation for assigns, events, and the messages each component sends to its parent LiveView. Sequence diagrams are available in [Webauthn Flows](./webauthn_flows.md).

## Support & Limitations

### WebAuthn vs. Passkeys

WebAuthn is the browser API; a Passkey is a credential created with that API. A Passkey may be stored on a single device or synchronized through a credential provider such as iCloud Keychain, Google Password Manager, or 1Password.

### Benefits

Passkeys eliminate password reuse, mitigate credential-stuffing attacks, and resist phishing.

### Browser support

Passkey support is broad across modern browsers; see [caniuse](https://caniuse.com/?search=webauthn). While this package targets browser-based WebAuthn, credentials may also be usable in native applications with appropriate configuration.

### Limitations

Cloud-synced credentials are only reachable from devices signed in to the same credential provider.

## Additional Resources

- [Webauthn Guide](https://webauthn.guide/)
- [MDN: Web Authentication API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API)
- [FIDO2: Web Authentication (WebAuthn)](https://fidoalliance.org/fido2-2/fido2-web-authentication-webauthn/)
- [W3C: Web Authentication: An API for accessing Public Key Credentials Level 2](https://www.w3.org/TR/webauthn-2/)
- [Apple: Passkeys Overview](https://developer.apple.com/passkeys/)
