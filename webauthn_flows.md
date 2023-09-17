# WebAuthn Flows

`WebauthnComponents` contains a few modular components which may be combined to detect passkey support, register new keys, authenticate keys for existing users, and manage session tokens in the client.

See module documentation for each component for more detailed descriptions.

### Support Detection

```mermaid
sequenceDiagram
   autonumber
   participant Client
   participant SupportComponent
   participant ParentLiveView
   participant RegistrationComponent
   participant AuthenticationComponent

   Client->>SupportComponent: "passkeys-supported"
   SupportComponent->>ParentLiveView: `{:passkeys_supported, boolean}`
   ParentLiveView->>RegistrationComponent: `@disabled = !@passkeys_supported`
   ParentLiveView->>AuthenticationComponent: `@disabled = !@passkeys_supported`
```

### Registration

A user wants to create a **new** account. If the user is already authenticated when they navigate to `/sign-in`, the LiveView will redirect to `/`.

```mermaid
sequenceDiagram
   autonumber
   actor User
   participant Client
   participant RegistrationComponent
   participant ParentLiveView

   User->>Client: Click `register`
   Client->>RegistrationComponent: "register"
   RegistrationComponent->>Client: "registration-challenge"
   Client->>RegistrationComponent: "registration-attestation"
   RegistrationComponent->>ParentLiveView: `{:registration_successful, ...}`
```

Once the parent LiveView receives the `{:registration_successful, ...}` message, it must persist the `%User{}` and `%UserKey{}`. The `wac.install` generator casts the new user key as an association in the user params, so both are created at once.

To keep the user signed in, the LiveView may [create a session token](#token-management).

### Authentication

A user wants to sign into an **existing** account. If the user is already authenticated when they navigate to `/sign-in`, the LiveView will redirect to `/`.

```mermaid
sequenceDiagram
   autonumber
   actor User
   participant Client
   participant AuthenticationComponent
   participant ParentLiveView

   User->>Client: Click `authenticate`
   Client->>AuthenticationComponent: "authenticate"
   AuthenticationComponent->>Client: "authentication-challenge"
   Client->>AuthenticationComponent: "authentication-attestation"
   AuthenticationComponent->>ParentLiveView: `{:find_credential, ...}`
```

Once the parent LiveView receives the `{:find_credential, ...}` message, it must lookup the user via the user's existing key. To keep the user signed in, the LiveView may [create a session token](#token-management), Base64-encode the token, and pass it to `TokenComponent` for persistence in the client's `sessionStorage`.

### Token Management

A user has successfully registered or authenticated.

```mermaid
sequenceDiagram
   autonumber
   participant Client
   participant TokenComponent
   participant ParentLiveView

   ParentLiveView->>TokenComponent: `@token = b64_token`
   TokenComponent->>Client: "store-token"
   Client->>TokenComponent: "token-stored"
   TokenComponent->>ParentLiveView: `{:token_stored, ...}`
```

**Active Session**

```mermaid
sequenceDiagram
   autonumber
   participant Client
   participant TokenComponent
   participant ParentLiveView

   Client->>TokenComponent: "token-exists"
   TokenComponent->>ParentLiveView: `{:token_exists, ...}`
   ParentLiveView-->ParentLiveView: "[user lookup by token]"
```

**Sign Out**

```mermaid
sequenceDiagram
   autonumber
   participant Client
   participant TokenComponent
   participant ParentLiveView

   ParentLiveView->>TokenComponent: `@token = :clear`
   TokenComponent->>Client: "clear-token"
   Client->>TokenComponent: "token-cleared"
   TokenComponent->>ParentLiveView: `{:token_cleared}`
```
