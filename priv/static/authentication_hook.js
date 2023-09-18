import { base64ToArray, arrayBufferToBase64, handleError } from "./utils";

export const AuthenticationHook = {
  mounted() {
    console.info(`AuthenticationHook mounted`);

    this.handleEvent("authentication-challenge", (event) =>
      this.handlePasskeyAuthentication(event, this)
    );
  },

  async handlePasskeyAuthentication(event, context) {
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
