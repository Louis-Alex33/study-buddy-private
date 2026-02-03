# Rapport d'Audit de Sécurité - Studigo

**Date de l'audit:** Février 2026
**Version:** 1.0
**Statut:** À traiter

---

## Résumé Exécutif

L'application Studigo présente des **fondations de sécurité solides** (authentification Devise, session unique, rate limiting, IP limiting) mais souffre de **vulnérabilités critiques d'autorisation** permettant l'escalade horizontale de privilèges.

| Niveau | Nombre de problèmes |
|--------|-------------------|
| 🔴 Critique | 4 |
| 🟠 Important | 5 |
| 🟡 Moyen | 6 |
| 🟢 Amélioration | 4 |

---

## 1. Vulnérabilités Critiques (Action Immédiate Requise)

### 1.1 🔴 Escalade Horizontale - LecturesController

**Localisation:** `app/controllers/lectures_controller.rb`
**Actions affectées:** `show`, `edit`, `update`, `destroy`
**Impact:** Tout utilisateur authentifié peut voir, modifier ou supprimer n'importe quelle lecture

**Risque:**
- Accès aux données privées d'autres utilisateurs
- Suppression malveillante de contenu
- Violation RGPD (accès non autorisé aux données)

**Preuve de concept:**
```
# Bob accède à la lecture d'Alice (ID: 123)
GET /lectures/123
# → Succès (devrait être interdit)
```

**Recommandation:**
Ajouter un before_action de vérification d'ownership:
```ruby
before_action :authorize_lecture!, only: [:show, :edit, :update, :destroy]

def authorize_lecture!
  @lecture = current_user.lectures.find_by(id: params[:id])
  redirect_to lectures_path, alert: "Accès non autorisé" unless @lecture
end
```

**Priorité:** CRITIQUE
**Complexité:** Faible
**Effort estimé:** 30 minutes

---

### 1.2 🔴 Escalade Horizontale - QuizzesController

**Localisation:** `app/controllers/quizzes_controller.rb`
**Actions affectées:** `edit`, `update`, `destroy`
**Impact:** Tout utilisateur peut modifier ou supprimer n'importe quel quiz

**Recommandation:**
Implémenter une vérification d'ownership via la relation lecture → category → user

**Priorité:** CRITIQUE
**Complexité:** Faible
**Effort estimé:** 30 minutes

---

### 1.3 🔴 Escalade Horizontale - NotesController

**Localisation:** `app/controllers/notes_controller.rb`
**Action affectée:** `destroy`
**Impact:** Tout utilisateur peut supprimer les notes d'un autre

**Recommandation:**
```ruby
def destroy
  @note = current_user.notes.find(params[:id])
  # ...
end
```

**Priorité:** CRITIQUE
**Complexité:** Faible
**Effort estimé:** 15 minutes

---

### 1.4 🔴 Escalade Horizontale - FlashcardsController

**Localisation:** `app/controllers/flashcards_controller.rb`
**Actions affectées:** `destroy`, `update_progress`
**Impact:** Manipulation des flashcards d'autres utilisateurs

**Priorité:** CRITIQUE
**Complexité:** Faible
**Effort estimé:** 30 minutes

---

## 2. Problèmes Importants (Semaine 1-2)

### 2.1 🟠 Headers de Sécurité Désactivés

**Localisation:** `config/initializers/content_security_policy.rb`
**Problème:** CSP et Permissions-Policy entièrement commentés

**Impact:**
- Pas de protection XSS au niveau navigateur
- Pas de contrôle des fonctionnalités navigateur (caméra, micro, etc.)

**Recommandation:**
Activer une CSP minimale:
```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline
  end
end
```

**Priorité:** Important
**Complexité:** Moyenne (peut casser certaines fonctionnalités)
**Effort estimé:** 2 heures + tests

---

### 2.2 🟠 Politique de Mot de Passe Faible

**Localisation:** `config/initializers/devise.rb`
**Problème:** Minimum 6 caractères (recommandé: 12+)

**Recommandation:**
```ruby
config.password_length = 12..128
```

**Note:** Considérer une migration pour les utilisateurs existants ou appliquer uniquement aux nouveaux.

**Priorité:** Important
**Complexité:** Faible
**Effort estimé:** 15 minutes

---

### 2.3 🟠 Pas de Verrouillage de Compte

**Localisation:** `config/initializers/devise.rb` et `app/models/user.rb`
**Problème:** Module `:lockable` non activé

**Impact:** Attaques par force brute possibles sans limitation

**Recommandation:**
1. Ajouter `:lockable` au modèle User
2. Créer la migration pour les colonnes nécessaires
3. Configurer dans devise.rb:
```ruby
config.lock_strategy = :failed_attempts
config.unlock_strategy = :time
config.maximum_attempts = 10
config.unlock_in = 1.hour
```

**Priorité:** Important
**Complexité:** Moyenne
**Effort estimé:** 1 heure

---

### 2.4 🟠 Énumération d'Utilisateurs via Recherche

**Localisation:** `app/controllers/search_controller.rb`
**Problème:** La recherche retourne tous les utilisateurs correspondants

**Impact:**
- Collecte d'emails/noms d'utilisateurs
- Préparation d'attaques ciblées

**Recommandation:**
Limiter la recherche aux amis ou supprimer la recherche d'utilisateurs:
```ruby
@users = current_user.friends.where("...")
# ou
@users = [] # Désactiver complètement
```

**Priorité:** Important
**Complexité:** Faible
**Effort estimé:** 30 minutes

---

### 2.5 🟠 Détection Admin par Email

**Localisation:** `app/models/concerns/subscribable.rb`
**Problème:** Admin déterminé par comparaison d'email string

```ruby
ADMIN_EMAILS = %w[la@mail.com famille@studigo.fr].freeze
def admin?
  ADMIN_EMAILS.include?(email)
end
```

**Risque:** Si un utilisateur peut s'inscrire avec ces emails, il devient admin

**Recommandation:**
1. Ajouter une colonne `admin` boolean à la table users
2. Vérifier que les emails admin sont réservés ou déjà pris
3. Utiliser `user.admin?` basé sur la colonne

**Priorité:** Important
**Complexité:** Moyenne
**Effort estimé:** 1 heure

---

## 3. Problèmes Moyens (Mois 1)

### 3.1 🟡 Rate Limiting Basé sur Cache

**Localisation:** `app/controllers/concerns/rate_limitable.rb`
**Problème:** Le rate limiting utilise Rails.cache

**Risque:** Si le cache est vidé, les limites sont réinitialisées

**Recommandation:**
Utiliser une solution persistante (Redis avec INCR atomique) ou database-backed

**Priorité:** Moyen
**Complexité:** Moyenne
**Effort estimé:** 2 heures

---

### 3.2 🟡 Validation Content-Type Upload

**Localisation:** `app/models/lecture.rb`
**Problème:** Validation basée sur le header Content-Type (spoofable)

**Recommandation:**
Valider les magic bytes du fichier:
```ruby
def file_content_type
  return unless document.attached?

  actual_type = Marcel::MimeType.for(document.download, name: document.filename.to_s)
  unless ALLOWED_CONTENT_TYPES.include?(actual_type)
    errors.add(:document, "Type de fichier non autorisé")
  end
end
```

**Priorité:** Moyen
**Complexité:** Faible
**Effort estimé:** 1 heure

---

### 3.3 🟡 Pas de Scan Antivirus

**Problème:** Les fichiers uploadés ne sont pas scannés

**Recommandation:**
Intégrer ClamAV ou un service comme VirusTotal pour les scans asynchrones

**Priorité:** Moyen
**Complexité:** Haute
**Effort estimé:** 4-8 heures

---

### 3.4 🟡 WebSocket Authorization

**Localisation:** Channels Turbo/ActionCable
**Problème:** Vérification d'autorisation non visible dans les subscriptions

**Recommandation:**
Vérifier que les channels valident l'appartenance de l'utilisateur au room

**Priorité:** Moyen
**Complexité:** Moyenne
**Effort estimé:** 2 heures

---

### 3.5 🟡 Logs et Données Sensibles

**État actuel:** `filter_parameter_logging.rb` configuré correctement

**Recommandation supplémentaire:**
- Ajouter `:email` aux paramètres filtrés si nécessaire
- Configurer la rétention des logs
- S'assurer que les logs Heroku ne contiennent pas de données sensibles

**Priorité:** Moyen
**Complexité:** Faible
**Effort estimé:** 30 minutes

---

### 3.6 🟡 Vérification Signature Webhook Stripe

**Localisation:** `config/initializers/pay_webhooks.rb`
**État:** Le gem Pay gère normalement la vérification, mais à confirmer

**Recommandation:**
Vérifier que `STRIPE_SIGNING_SECRET` est configuré et que Pay valide les signatures

**Priorité:** Moyen
**Complexité:** Faible
**Effort estimé:** 30 minutes

---

## 4. Améliorations (Backlog)

### 4.1 🟢 Two-Factor Authentication (2FA)

**Recommandation:**
Implémenter via `devise-two-factor` gem pour les utilisateurs Pro ou sur demande

**Priorité:** Amélioration
**Complexité:** Haute
**Effort estimé:** 8-16 heures

---

### 4.2 🟢 Audit Logging

**Recommandation:**
Tracker les actions sensibles (login, changement email, suppression de données)

Gems recommandés: `paper_trail` ou `audited`

**Priorité:** Amélioration
**Complexité:** Moyenne
**Effort estimé:** 4 heures

---

### 4.3 🟢 Security Headers Additionnels

**Headers à ajouter:**
```ruby
# config/application.rb ou middleware
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'SAMEORIGIN',
  'X-Content-Type-Options' => 'nosniff',
  'X-XSS-Protection' => '1; mode=block',
  'Referrer-Policy' => 'strict-origin-when-cross-origin'
}
```

**Priorité:** Amélioration
**Complexité:** Faible
**Effort estimé:** 30 minutes

---

### 4.4 🟢 Détection d'Anomalies de Connexion

**Recommandation:**
Alerter l'utilisateur lors de connexion depuis un nouvel appareil/IP

**Priorité:** Amélioration
**Complexité:** Moyenne
**Effort estimé:** 4 heures

---

## 5. Points Positifs (Déjà en Place)

| Fonctionnalité | Status | Notes |
|----------------|--------|-------|
| Session Token Unique | ✅ | Empêche sessions multiples |
| IP Limiting | ✅ | Anti-fraude efficace |
| Rate Limiting AI | ✅ | Protège les endpoints IA |
| Strong Parameters | ✅ | Pas de mass assignment |
| Requêtes Paramétrées | ✅ | Protection SQL injection |
| CSRF Protection | ✅ | Activé par défaut |
| Password Hashing | ✅ | bcrypt avec 12 stretches |
| File Type Whitelist | ✅ | MIME types limités |
| File Size Limits | ✅ | Par plan (5MB/10MB) |
| Sensitive Param Filtering | ✅ | Logs protégés |

---

## 6. Tests de Sécurité Fournis

Les tests suivants ont été créés dans `test/security/`:

| Fichier | Couverture |
|---------|------------|
| `authorization_test.rb` | Escalade horizontale de privilèges |
| `authentication_test.rb` | Flux d'authentification, CSRF, fixation de session |
| `critical_flows_test.rb` | Parcours utilisateur critiques, XSS, injection |
| `robustness_test.rb` | Paramètres invalides, double soumission, limites |

**Exécution:**
```bash
rails test test/security/
```

**Note:** Certains tests vont **échouer intentionnellement** pour démontrer les vulnérabilités existantes.

---

## 7. Plan d'Action Recommandé

### Semaine 1 (Critique)
1. ✅ Fixer les 4 vulnérabilités d'autorisation (Lectures, Quizzes, Notes, Flashcards)
2. ✅ Activer CSP minimale
3. ✅ Renforcer la politique de mot de passe

### Semaine 2 (Important)
4. Activer le verrouillage de compte (Lockable)
5. Sécuriser la détection admin
6. Restreindre la recherche d'utilisateurs

### Mois 1 (Moyen)
7. Améliorer la validation des uploads
8. Renforcer le rate limiting
9. Ajouter les security headers

### Backlog (Amélioration)
10. Implémenter 2FA
11. Ajouter l'audit logging
12. Détection d'anomalies

---

## 8. Conformité RGPD - Points d'Attention

| Aspect | État | Action Requise |
|--------|------|----------------|
| Accès aux données personnelles | ⚠️ Vulnérable | Fixer l'autorisation |
| Suppression de compte | À vérifier | Tester le flow complet |
| Export de données | À vérifier | Implémenter si absent |
| Consentement cookies | À vérifier | Ajouter bannière si nécessaire |
| Chiffrement en transit | ✅ HTTPS | Via Heroku |
| Chiffrement au repos | ✅ | Via AWS S3/PostgreSQL |

---

## 9. Checklist de Déploiement Sécurisé

Avant chaque déploiement en production:

- [ ] Variables d'environnement sensibles non exposées
- [ ] Mode debug désactivé
- [ ] Logs ne contiennent pas de données sensibles
- [ ] Tests de sécurité passent
- [ ] Dépendances à jour (`bundle audit`)
- [ ] Pas de credentials dans le code

---

## Annexe A: Commandes Utiles

```bash
# Audit des gems pour vulnérabilités connues
bundle audit check --update

# Lancer les tests de sécurité
rails test test/security/

# Vérifier les routes exposées
rails routes | grep -E "(edit|update|destroy)"

# Vérifier la configuration Devise
rails c -e production
> Devise.mappings[:user].modules
```

---

## Annexe B: Ressources

- [OWASP Top 10](https://owasp.org/Top10/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Devise Security](https://github.com/heartcombo/devise#security)
- [Brakeman Scanner](https://brakemanscanner.org/)

---

**Fin du rapport**

*Ce rapport a été généré automatiquement dans le cadre d'un audit de sécurité. Les recommandations sont fournies à titre indicatif et doivent être validées avant implémentation.*
