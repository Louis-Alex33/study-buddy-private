import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectWrapper", "newWrapper", "select", "newInput"]

  showNew(event) {
    event.preventDefault()
    this.selectWrapperTarget.style.display = "none"
    this.newWrapperTarget.style.display = "block"
    this.selectTarget.value = ""
    this.newInputTarget.focus()
  }

  showSelect(event) {
    event.preventDefault()
    this.newWrapperTarget.style.display = "none"
    this.selectWrapperTarget.style.display = "block"
    this.newInputTarget.value = ""
  }
}
