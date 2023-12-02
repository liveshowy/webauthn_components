class BaseAbortControllerService {
  /**
   * Prepare an abort signal that will help support multiple auth attempts without needing to
   * reload the page.
   */
  createNewAbortSignal() {
    // Abort any existing calls to navigator.credentials.create() or navigator.credentials.get()
    if (this.controller) {
      const abortError = new Error(
        "Cancelling existing WebAuthn API call for new one"
      );
      abortError.name = "AbortError";
      this.controller.abort(abortError);
    }

    const newController = new AbortController();

    this.controller = newController;
    return newController.signal;
  }

  /**
   * Manually cancel any active WebAuthn registration or authentication attempt.
   */
  cancelCeremony() {
    if (this.controller) {
      const abortError = new Error(
        "Manually cancelling existing WebAuthn API call"
      );
      abortError.name = "AbortError";
      this.controller.abort(abortError);

      this.controller = undefined;
    }
  }
}

/**
 * A service singleton to help ensure that only a single navigator.crendetials ceremony is active at a time.
 *
 */
export const AbortControllerService = new BaseAbortControllerService();
