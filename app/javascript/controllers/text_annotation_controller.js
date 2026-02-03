import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "popup", "noteInput", "selectedTextInput", "textStartInput", "textEndInput"]
  static values = {
    lectureId: Number
  }

  connect() {
    this.hidePopup()
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  handleSelection(event) {
    const selection = window.getSelection()
    const selectedText = selection.toString().trim()

    if (selectedText.length > 0) {
      const range = selection.getRangeAt(0)
      const contentEl = this.contentTarget

      // Check if selection is within content
      if (!contentEl.contains(range.commonAncestorContainer)) {
        this.hidePopup()
        return
      }

      // Get text position relative to content
      const preSelectionRange = range.cloneRange()
      preSelectionRange.selectNodeContents(contentEl)
      preSelectionRange.setEnd(range.startContainer, range.startOffset)
      const textStart = preSelectionRange.toString().length
      const textEnd = textStart + selectedText.length

      // Store selection data
      this.selectedTextInputTarget.value = selectedText
      this.textStartInputTarget.value = textStart
      this.textEndInputTarget.value = textEnd

      // Position popup near selection
      const rect = range.getBoundingClientRect()
      this.showPopup(rect)
    } else {
      this.hidePopup()
    }
  }

  showPopup(rect) {
    const popup = this.popupTarget
    const scrollTop = window.scrollY || document.documentElement.scrollTop

    popup.style.top = `${rect.bottom + scrollTop + 10}px`
    popup.style.left = `${rect.left + (rect.width / 2)}px`
    popup.style.transform = "translateX(-50%)"
    popup.classList.remove("hidden")
    popup.classList.add("visible")

    // Focus input after small delay
    setTimeout(() => {
      this.noteInputTarget.focus()
    }, 100)
  }

  hidePopup() {
    if (this.hasPopupTarget) {
      this.popupTarget.classList.remove("visible")
      this.popupTarget.classList.add("hidden")
      this.noteInputTarget.value = ""
    }
  }

  handleClickOutside(event) {
    if (this.hasPopupTarget && !this.popupTarget.contains(event.target) && !this.contentTarget.contains(event.target)) {
      this.hidePopup()
    }
  }

  submitNote(event) {
    // Form will submit via Turbo, we just need to close popup after
  }

  closePopup() {
    this.hidePopup()
    window.getSelection().removeAllRanges()
  }

  onSubmitSuccess(event) {
    this.hidePopup()
    window.getSelection().removeAllRanges()
    // Refresh page to show annotations
    Turbo.visit(window.location.href, { action: "replace" })
  }
}
