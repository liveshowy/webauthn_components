# WebAuthn Flows

- [WebAuthn Flows](#webauthn-flows)
  - [Support Detection](#support-detection)
  - [Registration](#registration)
  - [Authentication](#authentication)
  - [Token Management](#token-management)


`WebauthnComponents` contains a few modular components which may be combined to detect passkey support, register new keys, authenticate keys for existing users, and manage session tokens in the client.

See module documentation for each component for more detailed descriptions.

> 🧯 The following charts focus on the success path, where no error has ocurred.

## Support Detection

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

## Registration

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

## Authentication

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
   ParentLiveView->>AuthenticationComponent: update: `%{user_keys: user_keys}`
   AuthenticationComponent->>AuthenticationComponent: validate challenge against user_keys
   AuthenticationComponent->>ParentLiveView: `{:authentication_successful, ...}`
```

Once the parent LiveView receives the `{:find_credential, ...}` message, it must lookup the user via the user's existing key. To keep the user signed in, the LiveView may [create a session token](#token-management), Base64-encode the token, and pass it to `TokenComponent` for persistence in the client's `sessionStorage`.

## Token Management

A user has successfully registered or authenticated.

The LiveView will render a separate hidden form on the page, with a text input for the `%UserToken{}` value. When this form is rendered, it will trigger a JS click on its own submit button, which will result in a `POST` to `/session`, protected by Phoenix's default CSRF protections ([Plug docs](https://hexdocs.pm/plug/Plug.CSRFProtection.html)).

The `Session` controller then validates the token before updating the connection session and redirecting to `/` upon success. If the token is invalid, the user will be redirected to `/sign-in` with a flash message to sign in.

**Successful Registration or Authentication**

A user has successfully registered or authenticated.

```mermaid
sequenceDiagram
   autonumber
   participant ParentLiveView
   participant TokenForm
   participant HomePage
   participant Router

   ParentLiveView->>TokenForm: `@form[:value].value = b64_token`
   TokenForm->>Session: submit POST to `/session`
   Session->>Session: create/2
   Session->>Session: lookup user by token
   Session->>Session: update conn session
   Session->>Router: redirect to `/`
```

**Active Session**

A user already has a valid session token.

```mermaid
sequenceDiagram
   autonumber
   participant Router
   participant Session

   Router->>Session: fetch_current_user/2
   Session->>Session: get session token
   Session->>Session: find user
   Session->>Session: put user_id in session
   Session->>Router: continue
```

**Sign Out**

A user has clicked the "Sign Out" button.

```mermaid
sequenceDiagram
   autonumber
   participant Client
   participant SignOut
   participant Router

   Client->>SignOut: Click
   SignOut->>Session: DELETE /session
   Session->>Session: delete all session tokens for user_id
   Session->>Session: clear the conn session
   Session->>Router: redirect to `/`
```
