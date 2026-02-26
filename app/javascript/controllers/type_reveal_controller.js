import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["letter", "letters"]

  connect() {
    // Animation is handled by CSS keyframes, but we can add
    // additional JS-driven effects here if needed
  }
}
