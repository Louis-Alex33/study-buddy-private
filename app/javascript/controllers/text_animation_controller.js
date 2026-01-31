import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (typeof anime !== 'undefined') {
      this.originalText = this.element.textContent
      this.splitText()
      this.animateText()
    }
  }

  disconnect() {
    // Clean up
  }

  splitText() {
    const text = this.element.textContent
    this.element.innerHTML = ''

    text.split('').forEach(char => {
      const span = document.createElement('span')
      if (char === ' ') {
        span.innerHTML = '&nbsp;'
      } else {
        span.textContent = char
      }
      span.style.display = 'inline-block'
      span.style.opacity = '0'
      this.element.appendChild(span)
    })
  }

  animateText() {
    const spans = this.element.querySelectorAll('span')

    anime.timeline({loop: false})
      .add({
        targets: spans,
        translateY: ['-2.75rem', 0],
        rotate: ['-1turn', 0],
        opacity: [0, 1],
        easing: 'easeOutExpo',
        duration: 1400,
        delay: anime.stagger(50),
        complete: () => {
          // After animation, restore original text so CSS .hero-highlight handles the gradient
          this.element.textContent = this.originalText
        }
      })
  }
}
