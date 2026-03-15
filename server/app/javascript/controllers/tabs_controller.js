import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]

  select(event) {
    const index = parseInt(event.currentTarget.dataset.index)

    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.className = tab.className.replace(/bg-\S+\s+text-\S+/, "")
        this.activeClasses.forEach(c => tab.classList.add(c))
        this.inactiveClasses.forEach(c => tab.classList.remove(c))
      } else {
        tab.className = tab.className.replace(/bg-\S+\s+text-\S+/, "")
        this.inactiveClasses.forEach(c => tab.classList.add(c))
        this.activeClasses.forEach(c => tab.classList.remove(c))
      }
    })

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
