import { handleError } from "./utils";

export const TokenHook = {
  mounted() {
    console.info(`TokenHook mounted`);

    this.handleEvent("store-token", (event) => this.storeToken(event, this));
    this.handleEvent("clear-token", () => this.clearToken(this));

    this.pushUserToken(this);
  },

  pushUserToken(context) {
    const token = window.sessionStorage.getItem("userToken");
    if (token) {
      context.pushEventTo(context.el, "token-exists", { token });
    }
  },

  storeToken({ token }, context) {
    try {
      window.sessionStorage.setItem("userToken", token);
      console.info(`Stored user token`);
      context.pushEventTo(context.el, "token-stored", { token });
    } catch (error) {
      console.error(error);
      handleError(error, context);
    }
  },

  clearToken(context) {
    try {
      window.sessionStorage.removeItem("userToken");
      console.info(`Cleared user token`);
      context.pushEventTo(context.el, "token-cleared", { token: null });
    } catch (error) {
      console.error(error);
      handleError(error, context);
    }
  },
};
