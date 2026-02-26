import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "percentage"]

  connect() {
    // Animate on connect
    requestAnimationFrame(() => {
      if (this.hasBarTarget) {
        this.barTarget.style.transition = "width 0.5s ease-out"
      }
    })
  }
}
