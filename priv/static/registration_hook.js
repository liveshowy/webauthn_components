import { base64ToArray, arrayBufferToBase64, handleError } from "./utils";
import { AbortControllerService } from "./abort_controller";

export const RegistrationHook = {
  mounted() {
    console.info(`RegistrationHook mounted`);

    this.handleEvent("registration-challenge", (event) =>
      this.handleRegistration(event, this)
    );
  },

  async handleRegistration(event, context) {
    try {
      const {
        attestation,
        challenge,
        excludeCredentials,
        residentKey,
        rp,
        timeout,
        user,
      } = event;
      const challengeArray = base64ToArray(challenge);

      user.id = base64ToArray(user.id).buffer;

      const publicKey = {
        attestation,
        authenticatorSelection: {
          authenticatorAttachment: "platform",
          residentKey: residentKey,
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
        signal: AbortControllerService.createNewAbortSignal(),
      });

      const { rawId, response, type } = credential;
      const { attestationObject, clientDataJSON } = response;
      const attestation64 = arrayBufferToBase64(attestationObject);
      const clientData = Array.from(new Uint8Array(clientDataJSON));
      const rawId64 = arrayBufferToBase64(rawId);

      context.pushEventTo(context.el, "registration-attestation", {
        attestation64,
        clientData,
        rawId64,
        type,
      });
    } catch (error) {
      if (error.toString().includes("NotAllowedError:")) {
        AbortControllerService.cancelCeremony();
      }
      console.error(error);
      handleError(error, context);
    }
  },
};
