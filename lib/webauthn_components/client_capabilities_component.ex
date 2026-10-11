defmodule WebauthnComponents.ClientCapabilitiesComponent do
  @moduledoc """
  A LiveComponent for detecting WebAuthn support.

  This component should be used in combination with `WebauthnComponents.RegistrationComponent` and `WebauthnComponents.AuthenticationComponent` to enable their buttons based on the client's capabilities.

  An application may also use `WebauthnComponents.ClientCapabilitiesComponent` to steer users away from traditional authentication to the more secure Passkey authentication method.
  For example, an application that supports both traditional authentication and Passkeys may redirect users to a Passkey LiveView or render a message encouraging the new authentication method.

  > ### Compatibility {: .info}
  >
  > Since early 2025, major browsers support `PublicKeyCredential.getClientCapabilities()`.
  > Unsupported browsers raise an error, which the component forwards to the parent LiveView as `{:invalid_event, "error", payload}`.
  >
  > See [caniuse](https://caniuse.com/?search=getClientCapabilities) for support details.

  ## Assigns

  - `@id` (Required) An HTML element ID.

  ## Messages

  - `{:client_capabilities, capabilities}`: Sent to the parent LiveView.
  - `{:invalid_event, event, payload}`: Sent when an invalid event is received. This will typically be a client-side error message.

  ### Example Capabilities

  The component passes the JSON-decoded capabilities map to the parent LiveView.
  The keys are camelCase string keys as defined by the WebAuthn specification.

  ```elixir
  %{
    "conditionalCreate" => false,
    "conditionalGet" => true,
    "extension:credProps" => true,
    "extension:prf" => true,
    "hybridTransport" => true,
    "passkeyPlatformAuthenticator" => true,
    "relatedOrigins" => true,
    "signalAllAcceptedCredentials" => false,
    "signalCurrentUserDetails" => false,
    "signalUnknownCredential" => false,
    "userVerifyingPlatformAuthenticator" => true
  }
  ```

  This map allows detection of credential features supported by the current user's browser.
  You may allow or deny access based on your risk profile and security requirements.

  See [`PublicKeyCredential.getClientCapabilities()`](https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredential/getClientCapabilities) for details.

  > ### Design Decision {: .info}
  >
  > You may notice this is a plain map with camelCase string keys, passed unmodified from the client.
  > Why not create a `%ClientCredentials{}` struct to aid in type checking and validation?
  >
  > These features may evolve over time with changes to the WebAuthn specification, and this approach allows for flexibility with minimal maintenance to `WebauthnComponents`.

  ## Usage

  The following example demonstrates how to use the `WebauthnComponents.ClientCapabilitiesComponent` to conditionally allow passkey registration based on the client's capabilities.

  ```elixir
  defmodule MyAppWeb.AuthenticationLive do
    def mount(socket) do
      {
        :ok,
        socket
        |> assign(:capabilities, %{})
      }
    end

    def handle_info({:client_capabilities, capabilities}, socket) do
      {:noreply, assign(socket, :capabilities, capabilities)}
    end
  end
  ```

  In the `c:Phoenix.LiveView.render/1` callback or an HEEx template, render the component(s):

  ```heex
  <.live_component module={WebauthnComponents.ClientCapabilitiesComponent} id="client-capabilities-component" />

  <.live_component
    :if={@capabilities["conditionalCreate"] and @capabilities["userVerifyingPlatformAuthenticator"]}
    module={WebauthnComponents.RegistrationComponent}
    id="registration-component"
    public_key_options={@public_key_options}
  />
  ```

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredential/getClientCapabilities_static
  """
  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <span id={@id} phx-hook="ClientCapabilitiesHook" phx-target={@myself} class="hidden"></span>
    """
  end

  def handle_event("client-capabilities", capabilities, socket) when is_map(capabilities) do
    send(self(), {:client_capabilities, capabilities})
    {:noreply, socket}
  end

  def handle_event(event, payload, socket) do
    send(self(), {:invalid_event, event, payload})
    {:noreply, socket}
  end
end
