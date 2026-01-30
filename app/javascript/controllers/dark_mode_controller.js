import { Controller } from "@hotwired/stimulus"

// Dark SaaS is the default (no attribute).
// Light mode sets data-theme="light" on both html and body.
export default class extends Controller {
  connect() {
    const saved = localStorage.getItem('theme')
    if (saved === 'light') {
      this.applyLight()
    } else if (saved === 'dark') {
      this.applyDark()
    } else {
      // No saved preference: detect system theme
      if (window.matchMedia('(prefers-color-scheme: light)').matches) {
        this.applyLight()
      } else {
        this.applyDark()
      }
    }
  }

  toggle() {
    const isLight = document.body.getAttribute('data-theme') === 'light'
    if (isLight) {
      this.applyDark()
      localStorage.setItem('theme', 'dark')
    } else {
      this.applyLight()
      localStorage.setItem('theme', 'light')
    }
  }

  applyLight() {
    document.documentElement.setAttribute('data-theme', 'light')
    document.body.setAttribute('data-theme', 'light')
  }

  applyDark() {
    document.documentElement.removeAttribute('data-theme')
    document.body.removeAttribute('data-theme')
  }
}
