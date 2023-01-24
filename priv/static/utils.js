function base64ToArray(base64String) {
  return Uint8Array.from(window.atob(base64String), (c) => c.charCodeAt(0));
}

function arrayBufferToBase64(buffer) {
  return window.btoa(
    Array.from(new Uint8Array(buffer), (c) => String.fromCharCode(c)).join("")
  );
}

function handleError(error, context) {
  console.error(`WebAuthn error:`, error);
  const { message, name, stack } = error;
  return context.pushEventTo(context.el, "error", { message, name, stack });
}

module.exports = { base64ToArray, arrayBufferToBase64, handleError };
