import { Controller } from "@hotwired/stimulus"

const STEPS = [
  "Analyse du contenu...",
  "Sélection des thèmes...",
  "Création des questions...",
  "Génération des choix...",
  "Finalisation du quiz..."
]

export default class extends Controller {
  submit() {
    const loading = document.createElement('div')
    loading.className = 'generation-loading'
    loading.innerHTML = `
      <div class="generation-loading-card">
        <div class="generation-loading-orb"></div>
        <div class="generation-loading-orb"></div>
        <div class="generation-loading-icon">
          <i class="fas fa-question-circle"></i>
        </div>
        <h2 class="generation-loading-title">Génération du quiz</h2>
        <p class="generation-loading-step">${STEPS[0]}</p>
        <div class="generation-loading-progress">
          <div class="generation-loading-progress-bar"></div>
        </div>
        <p class="generation-loading-hint">
          <i class="fas fa-circle-notch"></i>
          Cela peut prendre quelques secondes...
        </p>
      </div>
    `
    document.body.appendChild(loading)

    this.animateProgress(loading, STEPS)

    const modal = bootstrap.Modal.getInstance(document.getElementById('uploadModal'))
    if (modal) modal.hide()
  }

  animateProgress(container, steps) {
    const bar = container.querySelector('.generation-loading-progress-bar')
    const stepText = container.querySelector('.generation-loading-step')
    let currentStep = 0

    const interval = setInterval(() => {
      currentStep++
      if (currentStep >= steps.length) {
        clearInterval(interval)
        bar.style.width = '95%'
        return
      }
      stepText.style.opacity = '0'
      setTimeout(() => {
        stepText.textContent = steps[currentStep]
        stepText.style.opacity = '1'
      }, 300)
      bar.style.width = `${Math.min((currentStep + 1) / steps.length * 90, 90)}%`
    }, 3000)
  }
}
