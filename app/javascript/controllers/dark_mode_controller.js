import { Controller } from "@hotwired/stimulus"

// Dark SaaS is the default (no attribute).
// Light mode sets data-theme="light" on both html and body.
// localStorage 'theme': 'light' | 'dark' | absent (= follow system)
export default class extends Controller {
  connect() {
    const saved = localStorage.getItem('theme')

    // Migration: old code stored 'dark' by default — clear it so system detection works
    if (saved === 'dark') {
      localStorage.removeItem('theme')
      this.applySystem()
    } else if (saved === 'light') {
      this.applyLight()
    } else {
      this.applySystem()
    }
  }

  toggle() {
    const isLight = document.body.getAttribute('data-theme') === 'light'
    if (isLight) {
      this.applyDark()
      localStorage.setItem('theme', 'dark-manual')
    } else {
      this.applyLight()
      localStorage.setItem('theme', 'light')
    }
  }

  applySystem() {
    if (window.matchMedia('(prefers-color-scheme: light)').matches) {
      this.applyLight()
    } else {
      this.applyDark()
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
