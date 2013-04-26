module Macrophage
  class Web < Sinatra::Base
    enable :sessions, :logging
    use Rack::Flash
    set :public_folder, File.dirname(__FILE__) + '/../../public'
    set :views, File.dirname(__FILE__) + '/../../views'

    helpers do
      def heroku_host
        session[:heroku_host] || ENV['HEROKU_HOST'] || "heroku.com"
      end

      def start_session(token, heroku_host)
        begin
          session[:api_key] = token
          session[:heroku_host] = heroku_host
          user_info = heroku.request(
              :expects  => 200,
              :method   => :get,
              :path     => "/user"
          ).body
          session[:email] = user_info['email']
          redirect "/apps"
        rescue
          flash[:error] = "Invalid Token"
          redirect "/logout"
        end
      end

      def protected!
        unless (session.has_key? :api_key) && (session[:api_key].length > 0)
          #redirect "/login"
          redirect "https://id.#{heroku_host}/oauth/authorize?client_id=#{ENV['HEROKU_OAUTH_CLIENT_ID']}&response_type=code"
        end
      end

      def heroku()
        Excon.defaults[:ssl_verify_peer] = false
        Heroku::API.new(:api_key => session[:api_key], :host => "api.#{heroku_host}")
      end
    end

    post '/apps' do
      protected!
      action = Object::const_get('Macrophage').const_get('Actions').const_get(params[:action] + 'Action').new

      # TODO: check if correct action type

      # fire off the threads
      async_app_action_futures = {}
      params.each do |param|
        if param[0].match(/^actionable\//)
          app_name = param[0].split('/')[1]
          async_app_action_futures[app_name] = Thread.new do
            action.execute(heroku, app_name)
          end
          logger.info "[#{app_name}]: #{action.label_present} enqueued"
        end
      end

      # collect results
      successes = []
      failures = []
      async_app_action_futures.each do |app_name, action_future|
        begin
          logger.info "[#{app_name}]: #{action.label_present} dequeued"
          action_future.value
          successes << app_name
          logger.info "[#{app_name}]: #{action.label_present} completed"
        rescue Exception => e
          logger.error "[#{app_name}]: #{action.label_present} failed" +
              e.message +
              e.backtrace.inspect
          failures << app_name
        end
      end

      # prepare user messages
      unless successes.empty?
        flash[:success] = "Successfully #{action.label_past} #{action.label_mod} #{successes.join(", ")}"
      end
      unless failures.empty?
        flash[:error] = "Failed to #{action.label_past} #{action.label_mod} #{failures.join(", ")}"
      end

      redirect '/apps'
    end

    get '/apps' do
      protected!
      raw_apps = heroku.get_apps.body

      # this dictates the order of the fields, the label, and any conversion the value
      field_map = {
          'name' => {:label => 'Name'},
          'stack' => {:label => 'Stack'},
          'owner_email' => {:label => 'Owner', :value => lambda { |email| "<a href='mailto:#{email}'>#{email}</a>" }},
          'git_url' => {:label => 'Git URL'},
          'web_url' => {:label => 'Web URL', :value => lambda { |url| "<a href='#{url}' target='_blank'>#{url}</a>" }},
          'created_at' => {:label => 'Created Date', :value => lambda { |date_str| date_str.match(/[0-9\/]*/) }},
      }

      @apps = []
      raw_apps.each do |raw_app|
        if raw_app['owner_email'] != session[:email]
          next
        end

        app = {}
        field_map.each do |field_name, conversions|
          field_label = (conversions.has_key? :label) ? conversions[:label] : field_name
          field_value = (conversions.has_key? :value) ? conversions[:value].call(raw_app[field_name]) : raw_app[field_name]
          app[field_label] = field_value
        end
        @apps << app
      end

      if @apps.empty?
        flash[:info] = 'No apps? Go create some!'
      end

      @apps = @apps.sort_by do |a|
        a['Name']
      end

      erb :apps
    end

    get '/login' do
      erb :login
    end

    post '/login' do
      start_session params[:api_key], params[:heroku_host]
    end

    get '/oauth/heroku' do
      authJson = RestClient.post "https://id.#{heroku_host}/oauth/token",  {
          :grant_type => "authorization_code",
          :client_id => ENV['HEROKU_OAUTH_CLIENT_ID'],
          :client_secret => ENV['HEROKU_OAUTH_CLIENT_SECRET'],
          :code => params[:code]
      }

      auth = Heroku::API::OkJson.decode(authJson)
      start_session auth["access_token"], heroku_host
    end

    get '/logout' do
      session.clear
      redirect "/login"
    end

    get '/' do
      redirect "/apps"
    end
  end
end