import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Restore from sessionStorage if available
    this.restoreProgress()
  }

  restoreProgress() {
    // Local autosave handled by autosave_controller
  }
}
