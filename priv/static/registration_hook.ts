import { base64ToArray, arrayBufferToBase64, handleError } from "./utils";

export const RegistrationHook = {
  mounted() {
    console.info(`RegistrationHook mounted`);

    if (this.el.dataset.check_uvpa_available) {
      this.checkUserVerifyingPlatformAuthenticatorAvailable(this, {
        errorMessage: this.el.dataset.uvpa_error_message,
      });
    }

    this.handleEvent("registration-challenge", (event) => {
      if (event.authenticatorAttachment == this.el.dataset.authenticatorAttachment) {
        this.handleRegistration(event, this);
      }
    });
  },
  async checkUserVerifyingPlatformAuthenticatorAvailable(
    context,
    { errorMessage }
  ) {
    if (
      !(await window.PublicKeyCredential?.isUserVerifyingPlatformAuthenticatorAvailable())
    ) {
      const error = new Error(errorMessage);
      error.name = "NoUserVerifyingPlatformAuthenticatorAvailable";
      handleError(error, context);
      throw error;
    }
  },

  async handleRegistration(event, context) {
    try {
      const {
        attestation,
        authenticatorAttachment,
        challenge,
        excludeCredentials,
        residentKey,
        requireResidentKey,
        rp,
        timeout,
        user,
      } = event;
      const challengeArray = base64ToArray(challenge);

      user.id = base64ToArray(user.id).buffer;

      const publicKey: PublicKeyCredentialCreationOptions = {
        attestation,
        authenticatorSelection: {
          authenticatorAttachment: authenticatorAttachment,
          residentKey: residentKey,
          requireResidentKey: requireResidentKey,
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

      const credential = (await navigator.credentials.create({
        publicKey,
      })) as PublicKeyCredential;
      if (credential) {
        const { rawId, response, type } = credential;
        const { attestationObject, clientDataJSON } =
          response as AuthenticatorAttestationResponse;
        const attestation64 = arrayBufferToBase64(attestationObject);
        const clientData = Array.from(new Uint8Array(clientDataJSON));
        const rawId64 = arrayBufferToBase64(rawId);

        context.pushEventTo(context.el, "registration-attestation", {
          attestation64,
          clientData,
          rawId64,
          type,
        });
      }
    } catch (error) {
      console.error(error);
      handleError(error, context);
    }
  },
};
