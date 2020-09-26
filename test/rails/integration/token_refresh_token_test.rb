# frozen_string_literal: true

require "test_helper"

class RodauthOAuthRailsTokenRefreshTokenTest < RailsIntegrationTest
  include Rack::Test::Methods

  def test_token_rails_refresh_token_no_token
    setup_application
    header "Accept", "application/json"
    post("/token",
         client_secret: "CLIENT_SECRET",
         client_id: oauth_application[:client_id],
         grant_type: "refresh_token",
         refresh_token: "CODE")

    assert last_response.status == 400
    assert json_body["error"] == "invalid_grant"
  end

  def test_token_rails_refresh_token_revoked_token
    setup_application
    oauth_token = oauth_token(revoked_at: Sequel::CURRENT_TIMESTAMP)

    header "Accept", "application/json"
    post("/token",
         client_secret: "CLIENT_SECRET",
         client_id: oauth_application[:client_id],
         grant_type: "refresh_token",
         refresh_token: oauth_token[:refresh_token])

    assert last_response.status == 400
    assert json_body["error"] == "invalid_grant"
  end

  def test_token_refresh_token_no_client_secret
    setup_application

    header "Accept", "application/json"
    post("/token",
         client_id: oauth_application[:client_id],
         grant_type: "refresh_token",
         refresh_token: oauth_token[:refresh_token])

    assert last_response.status == 401
    assert json_body["error"] == "invalid_client"
  end

  def test_token_rails_refresh_token_successful
    setup_application

    header "Accept", "application/json"
    post("/token",
         client_secret: "CLIENT_SECRET",
         client_id: oauth_application[:client_id],
         grant_type: "refresh_token",
         refresh_token: oauth_token[:refresh_token])

    assert last_response.status == 200
    assert last_response.headers["Content-Type"] == "application/json"

    assert db[:oauth_tokens].count == 1

    verify_refresh_token_response(json_body, oauth_token)
  end
end
