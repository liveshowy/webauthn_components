export function base64ToArray(base64String) {
  const base64 = base64String.replace(/-/g, "+").replace(/_/g, "/");
  const padding = "=".repeat((4 - (base64.length % 4)) % 4);
  return Uint8Array.from(window.atob(base64 + padding), (c) => c.charCodeAt(0));
}

export function handleError(error, context) {
  console.error(`WebAuthn error:`, error);
  const { message, name, stack } = error;
  return context.pushEventTo(context.el, "error", { message, name, stack });
}
