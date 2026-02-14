import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.poll()
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  poll() {
    fetch(this.urlValue, {
      headers: { "Accept": "application/json" }
    })
      .then(response => response.json())
      .then(data => {
        if (data.ready) {
          window.location.reload()
        } else {
          this.timer = setTimeout(() => this.poll(), 3000)
        }
      })
      .catch(() => {
        this.timer = setTimeout(() => this.poll(), 5000)
      })
  }
}
