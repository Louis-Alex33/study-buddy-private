import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "popup", "noteInput", "selectedTextInput", "textStartInput", "textEndInput"]
  static values = {
    lectureId: Number,
    annotations: Array
  }

  connect() {
    this.hidePopup()
    document.addEventListener("click", this.handleClickOutside.bind(this))
    // Apply highlights after a short delay to ensure DOM is ready
    setTimeout(() => this.applyHighlights(), 100)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  applyHighlights() {
    // Get annotations from the notes list
    const notesList = document.getElementById('notes-list')
    if (!notesList) return

    const annotationItems = notesList.querySelectorAll('.annotation-item')
    const contentEl = this.contentTarget
    const textContent = contentEl.textContent

    annotationItems.forEach((item, index) => {
      const quoteEl = item.querySelector('.note-item-quote')
      if (!quoteEl) return

      // Extract the quoted text (remove surrounding quotes)
      let quotedText = quoteEl.textContent.trim()
      if (quotedText.startsWith('"')) quotedText = quotedText.slice(1)
      if (quotedText.endsWith('"')) quotedText = quotedText.slice(0, -1)
      if (quotedText.endsWith('...')) quotedText = quotedText.slice(0, -3)

      // Find and highlight in content
      this.highlightText(contentEl, quotedText, index)
    })
  }

  highlightText(container, searchText, annotationIndex) {
    if (!searchText || searchText.length < 3) return

    const walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, null, false)
    const nodesToProcess = []

    while (walker.nextNode()) {
      const node = walker.currentNode
      const nodeText = node.textContent
      const searchLower = searchText.toLowerCase()
      const nodeLower = nodeText.toLowerCase()

      // Check if this text node contains our search text
      const index = nodeLower.indexOf(searchLower)
      if (index !== -1) {
        nodesToProcess.push({ node, index, length: searchText.length, annotationIndex })
      }
    }

    // Process nodes in reverse to avoid offset issues
    nodesToProcess.reverse().forEach(({ node, index, length, annotationIndex }) => {
      const text = node.textContent
      const before = text.slice(0, index)
      const match = text.slice(index, index + length)
      const after = text.slice(index + length)

      const span = document.createElement('span')
      span.className = 'annotated-text'
      span.dataset.annotationIndex = annotationIndex
      span.innerHTML = match

      // Create marker
      const marker = document.createElement('span')
      marker.className = 'annotation-marker'
      marker.innerHTML = '<i class="fas fa-sticky-note"></i>'
      marker.dataset.annotationIndex = annotationIndex
      marker.addEventListener('click', (e) => {
        e.stopPropagation()
        this.scrollToAnnotation(annotationIndex)
      })

      const fragment = document.createDocumentFragment()
      if (before) fragment.appendChild(document.createTextNode(before))
      fragment.appendChild(span)
      fragment.appendChild(marker)
      if (after) fragment.appendChild(document.createTextNode(after))

      node.parentNode.replaceChild(fragment, node)
    })
  }

  scrollToAnnotation(index) {
    const notesList = document.getElementById('notes-list')
    const annotationItems = notesList.querySelectorAll('.annotation-item')
    if (annotationItems[index]) {
      annotationItems[index].scrollIntoView({ behavior: 'smooth', block: 'center' })
      annotationItems[index].classList.add('highlight-flash')
      setTimeout(() => annotationItems[index].classList.remove('highlight-flash'), 1500)
    }
  }

  handleSelection(event) {
    // Prevent default to stop any scroll behavior
    event.preventDefault()

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

      // Store scroll position before showing popup
      const scrollY = window.scrollY

      // Position popup near selection
      const rect = range.getBoundingClientRect()
      this.showPopup(rect, scrollY)
    } else {
      this.hidePopup()
    }
  }

  showPopup(rect, scrollY) {
    const popup = this.popupTarget

    // Position relative to viewport, accounting for current scroll
    const top = rect.bottom + scrollY + 10
    const left = rect.left + (rect.width / 2)

    popup.style.top = `${top}px`
    popup.style.left = `${left}px`
    popup.style.transform = "translateX(-50%)"
    popup.classList.remove("hidden")
    popup.classList.add("visible")

    // Focus input after small delay, prevent scroll
    setTimeout(() => {
      this.noteInputTarget.focus({ preventScroll: true })
    }, 100)
  }

  hidePopup() {
    if (this.hasPopupTarget) {
      this.popupTarget.classList.remove("visible")
      this.popupTarget.classList.add("hidden")
      if (this.hasNoteInputTarget) {
        this.noteInputTarget.value = ""
      }
    }
  }

  handleClickOutside(event) {
    if (this.hasPopupTarget && !this.popupTarget.contains(event.target) && !this.contentTarget.contains(event.target)) {
      this.hidePopup()
    }
  }

  closePopup() {
    this.hidePopup()
    window.getSelection().removeAllRanges()
  }

  onSubmitSuccess(event) {
    this.hidePopup()
    window.getSelection().removeAllRanges()
    // Reload page to show new highlight (Turbo will handle this smoothly)
    setTimeout(() => {
      Turbo.visit(window.location.href, { action: "replace" })
    }, 300)
  }
}
