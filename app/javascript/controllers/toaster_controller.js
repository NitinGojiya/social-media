// app/javascript/controllers/toaster_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "progress"]

  connect() {
    // Start the progress bar on the next frame
    requestAnimationFrame(() => {
      this.progressTarget.style.width = "100%";
    });

    // Auto-dismiss after 3 seconds
    this.timeout = setTimeout(() => {
      this.close();
    }, 3000);
  }

  close() {
    this.containerTarget.classList.add("opacity-0");
    this.containerTarget.classList.remove("opacity-100");

    // transition to complete before removing
    setTimeout(() => {
      this.containerTarget.remove();
    }, 500);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
