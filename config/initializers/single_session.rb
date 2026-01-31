# frozen_string_literal: true

# Enforce single active session per user.
# On every successful authentication (login, remember-me, password reset sign-in),
# a new session token is generated and stored in both the database and the
# Warden session. ApplicationController#verify_session_token! compares
# the two on every request — a mismatch triggers sign-out.

Warden::Manager.after_authentication do |user, warden, _options|
  token = SecureRandom.urlsafe_base64(32)
  user.update_column(:session_token, token)
  warden.session(:user)["session_token"] = token
end
