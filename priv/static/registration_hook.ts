import { base64ToArray, arrayBufferToBase64, handleError } from "./utils";

export const RegistrationHook = {
  mounted() {
    console.info(`RegistrationHook mounted`);

    this.handleEvent("registration-challenge", async ({ id, publicKey }) => {
      if (id == this.el.id) {
        try {
          publicKey.challenge = base64ToArray(publicKey.challenge).buffer;
          publicKey.user.id = base64ToArray(publicKey.user.id);
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
