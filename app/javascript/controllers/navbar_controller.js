import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["links", "burger"]

  toggle() {
    this.linksTarget.classList.toggle("navbar-links--open")
    this.burgerTarget.classList.toggle("is-active")
  }

  // Close menu when a link is clicked
  closeMenu() {
    this.linksTarget.classList.remove("navbar-links--open")
    this.burgerTarget.classList.remove("is-active")
  }
}
