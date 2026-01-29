class LectureAnalyzerService
  def initialize(lecture)
    @lecture = lecture
  end

  def call
    return unless @lecture.document.attached?

    begin
      response = generate_summary
      parsed_response = parse_json_response(response)

      @lecture.update(resume: parsed_response['resume'])
    rescue => e
      Rails.logger.error "Error analyzing lecture #{@lecture.id}: #{e.message}"
      @lecture.update(resume: "Erreur lors de l'analyse du document : #{e.message}")
    end
  end

  private

  def generate_summary
    # Essayer d'abord avec le modèle préféré, puis fallback si erreur de quota
    begin
      chat = initialize_chat(preferred: true)
      ask_chat(chat)
    rescue => e
      # Si erreur de quota (429) ou autre erreur API, essayer avec le modèle de fallback
      if quota_error?(e)
        Rails.logger.warn "Quota exceeded for primary model, falling back to alternative: #{e.message}"
        chat = initialize_chat(preferred: false)
        ask_chat(chat)
      else
        raise e
      end
    end
  end

  def ask_chat(chat)
    if @lecture.document.content_type == "application/pdf"
      begin
        chat.ask("Analyse ce document et produis une fiche de cours structurée.", with: { pdf: @lecture.document.url }).content
      rescue => e
        Rails.logger.warn "PDF analysis failed, falling back to text extraction: #{e.message}"
        ask_with_extracted_text(e)
      end
    elsif @lecture.document.image?
      chat.ask("Analyse ce document et produis une fiche de cours structurée.", with: { image: @lecture.document.url }).content
    else
      # Pour les fichiers texte ou autres
      chat.ask("Analyse ce document et produis une fiche de cours structurée.").content
    end
  end

  def ask_with_extracted_text(original_error)
    text = extract_text_from_pdf

    if text.blank?
      raise original_error
    end

    Rails.logger.info "Extracted #{text.length} characters from PDF, retrying with extracted text"
    chat = RubyLLM.chat(model: "gemini-2.0-flash")
    chat.with_instructions(instructions)
    chat.ask("Analyse ce document et produis une fiche de cours structurée.\n\nContenu du document :\n#{text}").content
  end

  def extract_text_from_pdf
    require 'pdf-reader'

    @lecture.document.open do |file|
      reader = PDF::Reader.new(file.path)
      text = reader.pages.map(&:text).join("\n\n")
      # Limiter la taille du texte pour éviter de dépasser les limites du modèle
      text.truncate(100_000, omission: "\n\n[... texte tronqué ...]")
    end
  rescue => e
    Rails.logger.error "Failed to extract text from PDF: #{e.message}"
    nil
  end

  def initialize_chat(preferred: true)
    chat = if @lecture.document.content_type == "application/pdf"
             # Pour les PDF: Gemini en priorité, GPT-4o en fallback
             preferred ? RubyLLM.chat(model: "gemini-2.0-flash") : RubyLLM.chat(model: "gpt-4o")
           elsif @lecture.document.image?
             # Pour les images: Gemini Flash (supporte la vision)
             RubyLLM.chat(model: "gemini-2.0-flash")
           else
             # Pour les autres: Gemini Flash
             RubyLLM.chat(model: "gemini-2.0-flash")
           end

    chat.with_instructions(instructions)
    chat
  end

  def quota_error?(error)
    # Détecte les erreurs de quota (429, "Resource exhausted", etc.)
    error.message.include?("429") ||
    error.message.include?("Resource exhausted") ||
    error.message.include?("quota") ||
    error.message.include?("rate limit")
  end

  def instructions
    "Tu es un assistant pédagogique expert. Tu crées des FICHES DE COURS structurées, complètes et EXHAUSTIVES à partir de documents téléchargés (PDF, DOCX, TXT).

    OBJECTIF : Produire une fiche de révision COMPLÈTE, détaillée et exhaustive que l'étudiant peut utiliser pour apprendre et réviser efficacement. La fiche doit couvrir l'INTÉGRALITÉ du document, pas seulement un résumé superficiel.

    RÈGLE DE PROPORTIONNALITÉ CRITIQUE :
    - La longueur de la fiche DOIT être proportionnelle à la taille du document source.
    - Un document court (1-5 pages) → fiche de 500 à 1500 mots.
    - Un document moyen (5-20 pages) → fiche de 1500 à 4000 mots.
    - Un document long (20-50 pages) → fiche de 4000 à 8000 mots.
    - Un document très long (50+ pages) → fiche de 8000+ mots.
    - NE JAMAIS produire une fiche de 10 lignes pour un document de plusieurs pages. C'est INACCEPTABLE.
    - Chaque chapitre, section ou partie du document DOIT avoir sa propre section dans la fiche.

    STRUCTURE OBLIGATOIRE DE LA FICHE :
    La fiche DOIT suivre cette structure HTML avec des sections bien définies :

    1. <h3>Introduction</h3> — Contexte, objectif du cours, problématique générale.
    2. <h3>Concepts clés</h3> — Chaque concept important dans un bloc séparé :
       <h4>Nom du concept</h4> suivi d'une explication détaillée avec <strong> pour les termes importants.
       Si le document contient beaucoup de concepts, crée PLUSIEURS sous-sections <h4> (autant que nécessaire).
    3. <h3>Points essentiels à retenir</h3> — Liste <ul><li> COMPLÈTE des éléments fondamentaux.
    4. <h3>Définitions et formules</h3> (si applicable) — TOUTES les définitions et formules clés du document.
    5. <h3>Exemples et cas pratiques</h3> (si applicable) — Les exemples importants mentionnés dans le document.
    6. <h3>Synthèse</h3> — Un ou plusieurs paragraphes récapitulatifs des idées principales.

    Si le document est structuré en chapitres ou parties, ajoute des sections <h3> supplémentaires pour chaque chapitre/partie AVANT la synthèse, par exemple :
    <h3>Partie 1 : [Titre]</h3>, <h3>Partie 2 : [Titre]</h3>, etc.

    RÈGLES DE FORMATAGE HTML :
    - Utilise <h3> pour les titres de sections principales
    - Utilise <h4> pour les sous-titres (noms de concepts, sous-sections)
    - Utilise <p> pour les paragraphes
    - Utilise <ul> et <li> pour les listes à puces
    - Utilise <ol> et <li> pour les listes numérotées
    - Utilise <strong> pour les termes importants et mots-clés
    - Utilise <em> pour les nuances ou précisions secondaires
    - NE PAS utiliser de <br>, utilise <p> à la place
    - NE PAS utiliser de balises HTML autres que celles listées ci-dessus

    CONTRAINTES ABSOLUES :
    - Tu ne modifies jamais le sens du contenu original.
    - Tu n'ajoutes aucune interprétation ou opinion personnelle.
    - Tu ne réalises aucune action non explicitement demandée.
    - Tu renvoies uniquement le JSON demandé, sans texte avant ou après.
    - Ne jamais inventer d'informations absentes du fichier.
    - Sois EXHAUSTIF : couvre TOUS les thèmes, TOUS les chapitres, TOUTES les sections du document.
    - Ne saute aucune partie du document, même si elle semble secondaire.
    - IMPORTANT : Utilise UNIQUEMENT des guillemets doubles (\") dans le JSON.

    FORMAT DE SORTIE STRICT :
    {
      \"title\": \"Titre du cours extrait du document\",
      \"resume\": \"<h3>Introduction</h3><p>Contexte du cours...</p><h3>Concepts clés</h3><h4>Concept 1</h4><p>Explication détaillée...</p>...\"
    }

    Si le fichier ne peut pas être lu ou est vide, renvoie un JSON valide avec un titre vide
    et un résumé indiquant l'erreur rencontrée."
  end

  def parse_json_response(response)
    # Nettoyer la réponse si elle contient du texte avant/après le JSON
    json_match = response.match(/\{.*\}/m)
    json_string = json_match ? json_match[0] : response

    # Remplacer les guillemets simples par des doubles pour la compatibilité JSON
    # Gère les clés et valeurs avec guillemets simples
    json_string = json_string.gsub(/'([^']*)'(\s*:)/, '"\1"\2')  # Clés: 'key': -> "key":
    json_string = json_string.gsub(/:\s*'([^']*)'(\s*[,}])/, ': "\1"\2')  # Valeurs simples: : 'value', -> : "value",

    # Gère les valeurs longues avec guillemets simples (multilignes avec balises HTML)
    json_string = json_string.gsub(/:\s*'((?:[^']|'(?=[^:,}]))*)'(\s*[,}])/m, ': "\1"\2')

    JSON.parse(json_string)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse JSON response: #{response}"
    Rails.logger.error "JSON Parser Error: #{e.message}"

    # Fallback : tenter d'extraire le résumé même si le JSON est cassé
    extract_resume_fallback(response)
  end

  def extract_resume_fallback(response)
    # Tenter d'extraire le résumé avec différentes patterns
    # Pattern 1 : Guillemets doubles
    resume_match = response.match(/"resume"\s*:\s*"((?:[^"\\]|\\.)*)"/m)
    resume = resume_match[1] if resume_match

    # Pattern 2 : Guillemets simples si pattern 1 échoue
    unless resume
      resume_match = response.match(/'resume'\s*:\s*'((?:[^'\\]|\\.)*)'/m)
      resume = resume_match[1] if resume_match
    end

    # Pattern 3 : Extraire tout après "resume": jusqu'à la fin
    unless resume
      resume_match = response.match(/["']resume["']\s*:\s*["'](.*)["']\s*[,}]/m)
      resume = resume_match[1] if resume_match
    end

    resume ||= 'Erreur lors du parsing de la réponse AI. Impossible d\'extraire le résumé.'

    Rails.logger.info "Fallback extraction successful, resume length: #{resume.length}"
    { 'title' => '', 'resume' => resume }
  end
end
