const SupportHook = {
  mounted() {
    console.info(`SupportHook mounted`);

    const supported = "credentials" in navigator;

    if (!supported) {
      console.error(`WebAuthn not supported or enabled.`);
    }

    this.pushEventTo(this.el, "passkeys-supported", { supported });
  },
};

module.exports = { SupportHook };
