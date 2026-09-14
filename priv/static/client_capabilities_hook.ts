export const ClientCapabilitiesHook = {
  async mounted() {
    console.info(`ClientCapabilitiesHook mounted`);
    const capabilities = await PublicKeyCredential.getClientCapabilities();
    this.pushEventTo(this.el, "client-capabilities", capabilities);
    return;
  },
};
