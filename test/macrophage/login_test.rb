require File.expand_path('../../../lib/macrophage', __FILE__)

require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

module Macrophage
  class LoginTest < Test::Unit::TestCase
    include Rack::Test::Methods

    def app
      Macrophage::Web
    end

    def test_redirect_to_login
      get '/'
      assert last_response.redirect?

      follow_redirect!
      assert_equal "http://example.org/login", last_request.url
      assert last_response.ok?
    end

    def test_unauthenticated_redirect_to_login
      get '/apps'
      assert last_response.redirect?

      follow_redirect!
      assert_equal "http://example.org/login", last_request.url
      assert last_response.ok?
    end

    #def test_authenticated_no_direct_to_login
    #  session = Rack::Session::Abstract::SessionHash.new()
    #  session[:api_key] = 'b'
    #
    #  get '/apps', {}, {'rack.session' => session}
    #  assert_false last_response.redirect?
    #  assert last_response.ok?
    #end
  end
end