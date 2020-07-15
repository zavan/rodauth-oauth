# frozen_string_literal: true

require "test_helper"

class RodauthOAuthOIDCTokenUserInfoTest < OIDCIntegration
  include Rack::Test::Methods

  def test_oidc_userinfo_openid
    setup_application

    access_token = generate_access_token("openid")
    login(access_token)

    @json_body = nil
    get("/userinfo")

    assert last_response.status == 200
    assert json_body.key?("sub")
  end

  def test_oidc_userinfo_email
    setup_application

    access_token = generate_access_token("openid email")
    login(access_token)

    @json_body = nil
    # valid token, and now we're getting somewhere
    get("/userinfo")

    assert last_response.status == 200
    assert json_body.key?("sub")
    assert json_body.key?("email")
    assert json_body["email_verified"] == true
  end

  def test_oidc_userinfo_email_email
    setup_application

    access_token = generate_access_token("openid email.email")
    login(access_token)

    @json_body = nil
    # valid token, and now we're getting somewhere
    get("/userinfo")

    assert last_response.status == 200
    assert json_body.key?("sub")
    assert json_body.key?("email")
    assert !json_body.key?("email_verified")
  end

  private

  def setup_application
    rodauth do
      oauth_jwt_key "SECRET"
      oauth_jwt_algorithm "HS256"
      get_oidc_param do |token, param|
        @account ||= db[:accounts].where(id: token["sub"]).first

        return unless @account

        case param
        when :email_verified
          @account[:status_id] == account_open_status_value
        else
          @account[param]
        end
      end
    end

    super
  end

  # overriding to implement the client/secret basic authorization
  def login(token)
    header "Authorization", "Bearer #{token}"
  end

  def generate_access_token(scopes = "openid")
    grant = oauth_grant(scopes: scopes)

    post("/oauth-token",
         client_id: oauth_application[:client_id],
         client_secret: "CLIENT_SECRET",
         grant_type: "authorization_code",
         code: grant[:code],
         redirect_uri: grant[:redirect_uri])

    verify_response

    verify_oauth_token
    json_body["access_token"]
  end
end
