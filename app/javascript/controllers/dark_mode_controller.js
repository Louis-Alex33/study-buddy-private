import { Controller } from "@hotwired/stimulus"

// Dark SaaS is the default (no attribute on body).
// Light mode sets data-theme="light".
export default class extends Controller {
  connect() {
    const saved = localStorage.getItem('theme')
    if (saved === 'light') {
      document.body.setAttribute('data-theme', 'light')
    } else {
      document.body.removeAttribute('data-theme')
      localStorage.setItem('theme', 'dark')
    }
  }

  toggle() {
    const isLight = document.body.getAttribute('data-theme') === 'light'
    if (isLight) {
      document.body.removeAttribute('data-theme')
      localStorage.setItem('theme', 'dark')
    } else {
      document.body.setAttribute('data-theme', 'light')
      localStorage.setItem('theme', 'light')
    }
  }
}
