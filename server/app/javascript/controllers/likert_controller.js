import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "option", "skipField"]

  select(event) {
    // Visual feedback is handled by CSS :has(:checked)
  }

  submit() {
    // Small delay for visual feedback
    setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 200)
  }

  skip() {
    this.skipFieldTarget.value = "1"
    // Clear any selected radio
    this.formTarget.querySelectorAll('input[type="radio"]').forEach(r => r.checked = false)
    this.formTarget.requestSubmit()
  }
}
