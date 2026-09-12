export const SupportHook = {
  async mounted() {
    console.info(`SupportHook mounted`);
    const capabilities = await PublicKeyCredential.getClientCapabilities();
    this.pushEventTo(this.el, "client-capabilities", capabilities);
    return;
  },
};
