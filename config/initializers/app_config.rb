# Centralise l'URL du site pour faciliter la migration vers studigo.fr
# Pour changer : heroku config:set APP_URL=https://studigo.fr
Rails.application.config.app_host = ENV.fetch('APP_URL', 'https://studigo-5605123477b4.herokuapp.com')
