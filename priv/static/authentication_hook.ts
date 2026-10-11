import { base64ToArray, handleError } from "./utils";

export const AuthenticationHook = {
  mounted() {
    console.info(`AuthenticationHook mounted`);

    this.handleEvent("get-credential", async ({ id, publicKey, mediation }) => {
      try {
        publicKey.challenge = base64ToArray(publicKey.challenge).buffer;
        publicKey.allowCredentials = publicKey.allowCredentials.map((credential) => {
            return credential.id = base64ToArray(credential.id).buffer;
          });
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
