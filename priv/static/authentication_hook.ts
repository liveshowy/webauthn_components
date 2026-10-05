import { base64ToArray, arrayBufferToBase64, handleError } from "./utils";

export const AuthenticationHook = {
  mounted() {
    console.info(`AuthenticationHook mounted`);

    this.handleEvent("get-credential", async ({id, publicKey, mediation}) => {
      publicKey.challenge = base64ToArray(publicKey.challenge).buffer;
      publicKey.allowCredentials = publicKey.allowCredentials.map((credential) => {
        credential.id = base64ToArray(credential.id).buffer;
      });
      const credential = await navigator.credentials.get({ publicKey, mediation });
      this.pushEventTo(this.el, "credential", credential);
    })
  },
};
