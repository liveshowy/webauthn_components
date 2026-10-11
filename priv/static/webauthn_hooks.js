export const ClientCapabilitiesHook = {
  async mounted() {
    console.info(`ClientCapabilitiesHook mounted`);
    try {
      const capabilities = await PublicKeyCredential.getClientCapabilities();
      this.pushEventTo(this.el, "client-capabilities", capabilities);
    } catch (error) {
      console.error(error);
      handleError(error, this);
    }
  },
};

export const RegistrationHook = {
  mounted() {
    console.info(`RegistrationHook mounted`);

    this.handleEvent("registration-challenge", async ({ id, publicKey }) => {
      if (id == this.el.id) {
        try {
          publicKey.challenge = base64ToArray(publicKey.challenge).buffer;
          publicKey.user.id = base64ToArray(publicKey.user.id).buffer;
          publicKey.excludeCredentials = (
            publicKey.excludeCredentials || []
          ).map((credential) => ({
            ...credential,
            id: base64ToArray(credential.id).buffer,
          }));
          const credential = await navigator.credentials.create({ publicKey });
          this.pushEventTo(this.el, "credential", credential);
        } catch (error) {
          console.error(error);
          handleError(error, this);
        }
      }
    });
  },
};

export const AuthenticationHook = {
  mounted() {
    console.info(`AuthenticationHook mounted`);

    this.handleEvent("get-credential", async ({ id, publicKey, mediation }) => {
      try {
        publicKey.challenge = base64ToArray(publicKey.challenge).buffer;
        publicKey.allowCredentials = publicKey.allowCredentials.map(
          (credential) => ({
            ...credential,
            id: base64ToArray(credential.id).buffer,
          })
        );
        const credential = await navigator.credentials.get({
          publicKey,
          mediation,
        });
        this.pushEventTo(this.el, "credential", credential);
      } catch (error) {
        console.error(error);
        handleError(error, this);
      }
    });
  },
};

function base64ToArray(base64String) {
  const base64 = base64String.replace(/-/g, "+").replace(/_/g, "/");
  const padding = "=".repeat((4 - (base64.length % 4)) % 4);
  return Uint8Array.from(window.atob(base64 + padding), (c) => c.charCodeAt(0));
}

function handleError(error, context) {
  console.error(`WebAuthn error:`, error);
  const { message, name, stack } = error;
  return context.pushEventTo(context.el, "error", { message, name, stack });
}
