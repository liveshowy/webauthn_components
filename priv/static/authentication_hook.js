import { base64ToArray, arrayBufferToBase64, handleError } from "./utils";
import { browserSupportsPasskeyAutofill } from "./browser_supports_passkey_autofill";

export const AuthenticationHook = {
  mounted() {
    console.info(`AuthenticationHook mounted`);

    if (!this.el.dataset.skipConditionalUiCheck) {
      this.checkConditionalUIAvailable(this);
    }

    this.handleEvent("authentication-challenge", (event) =>
      this.handlePasskeyAuthentication(event, this, "optional")
    );

    this.handleEvent("authentication-challenge-with-conditional-ui", (event) =>
      this.handlePasskeyAuthentication(event, this, "conditional")
    );
  },

  async checkConditionalUIAvailable(context) {
    if (!(await browserSupportsPasskeyAutofill())) {
      throw Error("Browser does not support WebAuthn autofill");
    }

    // Check for an <input> with "webauthn" in its `autocomplete` attribute
    const eligibleInputs = document.querySelectorAll(
      "input[autocomplete$='webauthn']"
    );

    // WebAuthn autofill requires at least one valid input
    if (eligibleInputs.length < 1) {
      throw Error(
        'No <input> with "webauthn" as the only or last value in its `autocomplete` attribute was detected'
      );
    }

    context.pushEventTo(context.el, "authenticate", {
      supports_passkey_autofill: true,
    });
  },

  async handlePasskeyAuthentication(event, context, mediation) {
    try {
      const { challenge, timeout, rpId, allowCredentials, userVerification } =
        event;

      const challengeArray = base64ToArray(challenge);

      const publicKey = {
        allowCredentials,
        challenge: challengeArray.buffer,
        rpId,
        timeout,
        userVerification,
      };
      const credential = await navigator.credentials.get({
        publicKey,
        mediation: mediation,
      });
      const { rawId, response, type } = credential;
      const { clientDataJSON, authenticatorData, signature, userHandle } =
        response;
      const rawId64 = arrayBufferToBase64(rawId);
      const clientDataArray = Array.from(new Uint8Array(clientDataJSON));
      const authenticatorData64 = arrayBufferToBase64(authenticatorData);
      const signature64 = arrayBufferToBase64(signature);
      const userHandle64 = arrayBufferToBase64(userHandle);

      context.pushEventTo(context.el, "authentication-attestation", {
        rawId64,
        type,
        clientDataArray,
        authenticatorData64,
        signature64,
        userHandle64,
      });
    } catch (error) {
      console.error(error);
      handleError(error, context);
    }
  },
};
