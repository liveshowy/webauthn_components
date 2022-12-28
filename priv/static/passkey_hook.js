const PasskeyHook = {
  // PROPERTIES

  abortController: new AbortController(),

  // LIVEVIEW HOOK CALLBACKS

  mounted() {
    console.info(`PasskeyHook mounted`);

    if (!("credentials" in navigator)) {
      console.error(`Passkeys are not supported by this browser`);
      this.pushEventTo(this.el, "passkeys-supported", false);
      return;
    }

    this.pushEventTo(this.el, "passkeys-supported", true);
    this.pushUserToken(this);
    this.attachEventListeners(this);

    return;
  },

  destroyed() {
    return this.detachEventListeners();
  },

  // CUSTOM METHODS

  attachEventListeners(context) {
    listenerOptions = { signal: context.abortController.signal };

    window.addEventListener("phx:passkey-registration", (event) =>
      this.handlePasskeyRegistration(event, context)
    );

    window.addEventListener("phx:passkey-authentication", (event) =>
      this.handlePasskeyAuthentication(event, context)
    );

    window.addEventListener(
      "phx:store-token",
      (event) => context.storeToken(event, context),
      listenerOptions
    );

    window.addEventListener(
      "phx:clear-token",
      (_event) => context.clearToken(null, context),
      listenerOptions
    );

    return;
  },

  detachEventListeners() {
    window.removeEventListener(
      "phx:passkey-authentication",
      this.handlePasskeyAuthentication
    );
    window.removeEventListener("phx:store-token", this.storeToken);
    window.removeEventListener("phx:clear-token", this.clearToken);

    return;
  },

  // PASSKEY HANDLERS

  async handlePasskeyRegistration(event, context) {
    try {
      const { attestation, challenge, excludeCredentials, rp, timeout, user } =
        event.detail;
      const challengeArray = this.base64ToArray(challenge);

      user.id = this.base64ToArray(user.id).buffer;

      const publicKey = {
        attestation,
        authenticatorSelection: {
          authenticatorAttachment: "platform",
          requireResidentKey: true,
        },
        challenge: challengeArray.buffer,
        excludeCredentials,
        pubKeyCredParams: [
          { alg: -7, type: "public-key" },
          { alg: -257, type: "public-key" },
        ],
        rp,
        timeout,
        user,
      };

      const credential = await navigator.credentials.create({
        publicKey,
      });

      const { rawId, response, type } = credential;
      const { attestationObject, clientDataJSON } = response;
      const attestation64 = this.arrayBufferToBase64(attestationObject);
      const clientData = Array.from(new Uint8Array(clientDataJSON));
      const rawId64 = this.arrayBufferToBase64(rawId);

      return context.pushEventTo(context.el, "registration-attestation", {
        attestation64,
        clientData,
        rawId64,
        type,
      });
    } catch (error) {
      console.error(error);
      return this.handleError(error, context);
    }
  },

  async handlePasskeyAuthentication(event, context) {
    try {
      const { challenge, timeout, rpId, allowCredentials, userVerification } =
        event.detail;

      const challengeArray = this.base64ToArray(challenge);

      const publicKey = {
        allowCredentials,
        challenge: challengeArray.buffer,
        rpId,
        timeout,
        userVerification,
      };
      const credential = await navigator.credentials.get({
        publicKey,
      });
      const { rawId, response, type } = credential;
      const { clientDataJSON, authenticatorData, signature, userHandle } =
        response;
      const rawId64 = this.arrayBufferToBase64(rawId);
      const clientDataArray = Array.from(new Uint8Array(clientDataJSON));
      const authenticatorData64 = this.arrayBufferToBase64(authenticatorData);
      const signature64 = this.arrayBufferToBase64(signature);
      const userHandle64 = this.arrayBufferToBase64(userHandle);

      return context.pushEventTo(context.el, "authentication-attestation", {
        rawId64,
        type,
        clientDataArray,
        authenticatorData64,
        signature64,
        userHandle64,
      });
    } catch (error) {
      console.error(error);
      return this.handleError(error, context);
    }
  },

  // TOKEN HANDLERS

  storeToken({ detail }, context) {
    try {
      const { token } = detail;
      window.sessionStorage.setItem("userToken", token);
      console.log(token, sessionStorage);
      console.info(`Stored user token`);
      return context.pushEventTo(context.el, "token-stored", { token });
    } catch (error) {
      console.error(error);
      return this.handleError(error, context);
    }
  },

  clearToken(_data, context) {
    try {
      window.sessionStorage.removeItem("userToken");
      console.log(sessionStorage);
      console.info(`Cleared user token`);
      return context.pushEventTo(context.el, "token-cleared", null);
    } catch (error) {
      console.error(error);
      return this.handleError(error, context);
    }
  },

  // HELPERS

  pushUserToken(context) {
    const token = window.sessionStorage.getItem("userToken");
    if (token) {
      return context.pushEventTo(context.el, "token-exists", { token });
    } else {
      return;
    }
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
    return context.pushEventTo(context.el, "error", { message, name, stack });
  },
};

module.exports = { PasskeyHook };
