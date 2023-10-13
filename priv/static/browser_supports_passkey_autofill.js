export function browserSupportsPasskeyAutofill() {
  const globalPublicKeyCredential = window.PublicKeyCredential;

  if (globalPublicKeyCredential.isConditionalMediationAvailable === undefined) {
    return new Promise((resolve) => resolve(false));
  }

  return globalPublicKeyCredential.isConditionalMediationAvailable();
}
