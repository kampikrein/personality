import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "domain"]

  connect() {
    // Animate bars after a short delay
    this.barTargets.forEach((bar, index) => {
      const finalWidth = bar.dataset.finalWidth
      setTimeout(() => {
        bar.style.width = `${finalWidth}%`
      }, 1600 + (index * 200))
    })
  }
}
