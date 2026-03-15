import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }

  connect() {
    this.key = this.keyValue || "assessment_progress"
  }

  save(data) {
    try {
      sessionStorage.setItem(this.key, JSON.stringify(data))
    } catch (e) {
      // sessionStorage might be unavailable
    }
  }

  load() {
    try {
      const data = sessionStorage.getItem(this.key)
      return data ? JSON.parse(data) : null
    } catch (e) {
      return null
    }
  }

  clear() {
    try {
      sessionStorage.removeItem(this.key)
    } catch (e) {
      // ignore
    }
  }
}
