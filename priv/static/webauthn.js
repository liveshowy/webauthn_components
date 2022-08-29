const WebAuthn = {
  // PROPERTIES

  abortController: new AbortController(),

  // LIVEVIEW CALLBACKS

  mounted() {
    console.info(`WebAuthn hook mounted`);

    if (!("credentials" in navigator)) {
      console.error(`WebAuthn is not supported by this browser`);
      this.pushEventTo(this.el, "webauthn_supported", false);
      return;
    }

    console.info(`WebAuthn is supported by this browser`);

    this.pushEventTo(this.el, "webauthn_supported", true);
    this.pushUserToken(this);
    this.attachEventListeners(this);
  },

  destroyed() {
    this.abortController.abort();
    console.info(`WebAuthn hook destroyed`);
    this.removeEventListeners(this);
  },

  // EVENT LISTENERS

  attachEventListeners(context) {
    listenerOptions = { signal: context.abortController.signal };

    window.addEventListener(
      "phx:registration_challenge",
      (data) => context.handleRegistrationChallenge(data, context),
      listenerOptions
    );

    window.addEventListener(
      "phx:authentication_challenge",
      (data) => context.handleAuthenticationChallenge(data, context),
      listenerOptions
    );

    window.addEventListener(
      "phx:store_token",
      (data) => context.storeToken(data, context),
      listenerOptions
    );

    window.addEventListener(
      "phx:clear_token",
      (_data) => context.clearToken(null, context),
      listenerOptions
    );
  },

  removeEventListeners(context) {
    window.removeEventListener(
      "phx:registration_challenge",
      context.handleRegistrationChallenge
    );

    window.removeEventListener(
      "phx:authentication_challenge",
      context.handleAuthenticationChallenge
    );

    window.removeEventListener("phx:store_token", context.storeToken);

    window.removeEventListener("phx:clear_token", context.clearToken);
  },

  // WEBAUTHN HANDLERS

  async handleRegistrationChallenge(data, context) {
    try {
      let {
        appName,
        attestation,
        authenticator_attachment,
        challenge_64,
        rp_id,
        user,
        user_verification,
      } = data.detail;

      const challenge = this.base64ToArray(challenge_64);

      const publicKey = {
        challenge: challenge.buffer,
        rp: {
          name: appName,
          id: rp_id,
        },
        user: {
          id: user.id || new Uint8Array(16).buffer,
          name: user.name,
          displayName: user.displayName,
        },
        pubKeyCredParams: [{ alg: -7, type: "public-key" }],
        timeout: 60000,
        attestation: attestation,
        authenticatorSelection: {
          userVerification: user_verification,
        },
      };

      if (authenticator_attachment) {
        publicKey.authenticatorSelection.authenticatorSelection =
          authenticator_selection;
      }

      let { rawId, response, type } = await navigator.credentials.create({
        publicKey,
      });
      const { attestationObject, clientDataJSON } = response;

      const clientData = Array.from(new Uint8Array(clientDataJSON));
      const attestation64 = this.arrayBufferToBase64(attestationObject);
      const rawId64 = this.arrayBufferToBase64(rawId);

      context.pushEventTo(context.el, "registration_credentials", {
        attestation64,
        clientData,
        rawId64,
        type,
      });
    } catch (error) {
      this.handleError(error, context);
    }
  },
  async handleAuthenticationChallenge(data, context) {
    try {
      let { attestation, challenge_64, key_ids_64, user_verification } =
        data.detail;

      const allowCredentials = key_ids_64.map((base64KeyID) => {
        const keyID = this.base64ToArray(base64KeyID);
        return {
          id: keyID.buffer,
          type: "public-key",
          transports: ["usb", "ble", "nfc", "internal"],
        };
      });

      const challenge = this.base64ToArray(challenge_64);

      const publicKey = {
        allowCredentials,
        attestation,
        challenge: challenge.buffer,
        timeout: 60000,
        userVerification: user_verification,
      };
      const { rawId, type, response } = await navigator.credentials.get({
        publicKey,
      });
      const { clientDataJSON, authenticatorData, signature } = response;
      const rawId64 = this.arrayBufferToBase64(rawId);
      const clientDataArray = Array.from(new Uint8Array(clientDataJSON));
      const authenticatorData64 = this.arrayBufferToBase64(authenticatorData);
      const signature64 = this.arrayBufferToBase64(signature);

      context.pushEventTo(context.el, "authentication_attestation", {
        rawId64,
        type,
        clientDataArray,
        authenticatorData64,
        signature64,
      });
    } catch (error) {
      this.handleError(error, context);
    }
  },

  // TOKEN HANDLERS

  storeToken({ detail }, context) {
    try {
      const { token } = detail;
      window.sessionStorage.setItem("user_token", token);
      context.pushEventTo(context.el, "token_stored", { token });
    } catch (error) {
      this.handleError(error, context);
    }
  },
  clearToken(_data, context) {
    try {
      window.sessionStorage.removeItem("user_token");
      console.info(`Cleared user token`);
      context.pushEventTo(context.el, "token_cleared", {});
    } catch (error) {
      this.handleError(error, context);
    }
  },

  // HELPERS

  pushUserToken(context) {
    let user_token = window.sessionStorage.getItem("user_token");
    context.pushEventTo(context.el, "user_token", user_token);
  },
  base64ToArray(base64String) {
    return Uint8Array.from(window.atob(base64String), (c) => c.charCodeAt(0));
  },
  arrayBufferToBase64(buffer) {
    return window.btoa(
      Array.from(new Uint8Array(buffer), (c) => String.fromCharCode(c)).join("")
    );
  },
  handleError(error, context) {
    console.error(`WebAuthn error:`, error);
    const { message, name, stack } = error;
    context.pushEventTo(context.el, "error", { message, name, stack });
  },
};

module.exports = { WebAuthn };
