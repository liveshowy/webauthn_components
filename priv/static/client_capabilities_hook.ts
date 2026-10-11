import { handleError } from "./utils";

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
