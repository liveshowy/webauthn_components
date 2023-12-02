export function browserSupportsPasskeyAutofill() {
  const globalPublicKeyCredential = window.PublicKeyCredential;

  if (globalPublicKeyCredential.isConditionalMediationAvailable === undefined) {
    return Promise.resolve(false);
  }

  return globalPublicKeyCredential.isConditionalMediationAvailable();
}
