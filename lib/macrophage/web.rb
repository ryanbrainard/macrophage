module Macrophage
  class Web < Sinatra::Base
    enable :sessions, :logging
    use Rack::Flash

    before do
      unless request.path_info == '/login'
        unless (session.has_key? :api_key) && (session[:api_key].length > 0)
          redirect "/login"
        end
      end
    end

    post '/apps' do
      heroku = Heroku::API.new(:api_key => session[:api_key])
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
      heroku = Heroku::API.new(:api_key => session[:api_key])
      raw_apps = heroku.get_apps.body

      # this dictates the order of the fields, the label, and any conversion the value
      field_map = {
          'name' => {:label => 'Name'},
          'stack' => {:label => 'Stack'},
          'owner_email' => {:label => 'Owner', :value => lambda { |email| "<a href='mailto:#{email}'>#{email}</a>" }},
          'git_url' => {:label => 'Git URL'},
          'web_url' => {:label => 'Web URL', :value => lambda { |url| "<a href='#{url}' target='_blank'>#{url}</a>" }},
          'created_at' => {:label => 'Created Date'},
      }

      @apps = []
      raw_apps.each do |raw_app|
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

      erb :apps
    end

    get '/login' do
      erb :login
    end

    post '/login' do
      begin
        heroku = Heroku::API.new(:api_key => params[:api_key])
        user_info = heroku.get_user.body
        session[:email] = user_info['email']
        session[:api_key] = params[:api_key]
        redirect "/apps"
      rescue
        flash[:error] = "Invalid API Key"
        redirect "/logout"
      end
    end

    get '/logout' do
      session.clear
      redirect "/login"
    end

    get '/*' do
      redirect "/login"
    end
  end
end