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
    const url = `${this.urlValue}?t=${Date.now()}`
    fetch(url, {
      headers: { "Accept": "application/json" },
      cache: "no-store"
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
