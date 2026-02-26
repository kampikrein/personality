import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]
  static values = { start: Number }

  connect() {
    this.startTime = this.startValue || Date.now()
  }

  // Called before form submission to record response time
  fieldTargetConnected(field) {
    const form = field.closest("form")
    if (form) {
      form.addEventListener("submit", () => {
        field.value = Math.round(Date.now() - this.startTime)
      })
    }
  }
}
