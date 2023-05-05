# Usage

`WebauthnComponents` are designed to be modular, providing flexibility to developers. However, `SupportComponent` should always be rendered along with `RegistrationComponent` and `AuthenticationComponent` to detect WebAuthn support on the client.

A parent LiveView may also want to redirect users or clear tokens when users enter a page using the registration or authentication component. In these cases, render `TokenComponent` and implement its required message handlers to manage client-side session tokens.

## Contents

- [Usage](#usage)
  - [Contents](#contents)
  - [Combined Example](#combined-example)
  - [SupportComponent](#supportcomponent)
  - [TokenComponent](#tokencomponent)
  - [RegistrationComponent](#registrationcomponent)
  - [Authentication Component](#authentication-component)

## Combined Example

The following `AuthLive` example demonstrates how to compose the components to detect support, register, authenticate, and manage tokens in a single LiveView.

<!-- TODO: Render auth and token components, add handlers -->

```elixir
defmodule MyAppWeb.AuthLive do
  use Phoenix.LiveView
  alias WebauthnComponents.AuthenticationComponent
  alias WebauthnComponents.RegistrationComponent
  alias WebauthnComponents.SupportComponent
  alias WebauthnComponents.TokenComponent

  def mount(_session, _params, socket) do
    {
      :ok,
      socket
      |> assign(:passkeys_supported, fn -> nil end)
    }
  end

  def render(assigns) do
    ~H"""
    <section>
      <h1>Sign Up</h1>

      <.live_component
        module={SupportComponent}
        id="support-component"
      />

      <.live_component
        module={RegistrationComponent}
        id="registration-component"
        app={MyApp}
        disabled={@passkeys_supported == false}
      />
    </section>
    """
  end

  def handle_info({:passkeys_supported, true}, socket) do
    {
      :noreply,
      socket
      |> assign(:passkeys_supported, true)
    }
  end

  def handle_info({:passkeys_supported, false}, socket) do
    {
      :noreply,
      socket
      |> assign(:passkeys_supported, false)
      |> put_flash(:error, "Sorry, passkeys are not supported or enabled by this browser.")
    }
  end

  def handle_info({:registration_successful, key_id: raw_id, public_key: public_key}, socket) do
    # Persist the user here.
  end

  def handle_info({:registration_failure, message: message}, socket) do
    # Display the error message.
  end

  def handle_info({:error, payload}, socket) do
    # Display the error message.
  end
end
```

## SupportComponent

On its own, `SupportComponent` only reports whether the WebAuthn API is supported and enabled by the client. This may be useful for redirecting users away from traditional authentication for businesses mandating Passkey usage whenever possible.

<!-- TODO: Add example SupportComponent code -->

## TokenComponent

<!-- TODO: Add example TokenComponent code -->

## RegistrationComponent

<!-- TODO: Add example RegistrationComponent code -->

## Authentication Component

<!-- TODO: Add example AuthenticationComponent code -->
