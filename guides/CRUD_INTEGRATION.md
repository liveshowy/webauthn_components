# CRUD Integration

Create, Read, Update, Delete (CRUD) is the pattern established by traditional Phoenix code generators, including `phx.gen.auth`.
This guide documents the steps to integrate `WebauthnComponents` with an application where `phx.gen.auth` establishes the baseline authentication and session management mechanisms.
`WebauthnComponents` manages the client-server ceremonies for credential registration and authentication, and decisions about data storage are left to the host application.

The code examples in this guide may be modified to fit the naming conventions and particular requirements of your application.

## Outline

1. Generate a new Phoenix application
2. Generate authentication code
3. Add `WebauthnComponents` as a dependency
4. Add `WebauthnHooks` to `assets/js/app.js`
5. Add `PublicKeyCredential` schema and migration
6. Update `User` schema
7. Add functions to the `Accounts` context
8. Update `Settings` and `Login` LiveViews
9. Update `UserSessionController`
