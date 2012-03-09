require 'sinatra'
require 'sinatra/base'
require 'rack-flash'
require 'heroku-api'
require './lib/macrophage/pages'

enable :sessions
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

  # find the action we need
  action = case params[:action]
             when 'delete'
               {:label_present => 'delete',
                :label_past => 'deleted',
                :execution => lambda {
                    |app_name| heroku.delete_app(app_name)
                }}
             when 'maintenance_on'
               {:label_present => 'enable maintenance mode for',
                :label_past => 'enabled maintenance mode for',
                :execution => lambda { |app_name|
                  heroku.post_app_maintenance(app_name, 1)
                }}
             when 'maintenance_off'
               {:label_present => 'disable maintenance mode for',
                :label_past => 'disabled maintenance mode for',
                :execution => lambda { |app_name|
                  heroku.post_app_maintenance(app_name, 0)
                }}
             else
               raise 'Invalid app action'
           end

  # fire off the threads
  async_app_action_futures = {}
  params.each do |param|
    if param[0].match(/^actionable\//)
      app_name = param[0].split('/')[1]
      async_app_action_futures[app_name] = Thread.new do
        action[:execution].call(app_name)
      end
    end
  end

  # collect results
  successes = []
  failures = []
  async_app_action_futures.each do |app_name, future|
    begin
      future.value
      successes << app_name
    rescue
      failures << app_name
    end
  end

  # prepare user messages
  @message = ""
  unless successes.empty?
    @message << "Successfully " << action[:label_past] << " "<< successes.join(", ")
  end
  unless failures.empty?
    @message << " Failed to " << action[:label_present] << " " << failures.join(", ")
  end

  @apps = heroku.get_apps.body
  erb :apps
end

get '/apps' do
  heroku = Heroku::API.new(:api_key => session[:api_key])
  raw_apps = heroku.get_apps.body

  # this dictates the order of the fields, the label, and any conversion the value
  field_map = {
      'name' => {:label => 'Name'},
      'stack' => {:label => 'Stack', :value => lambda { |stack| stack.capitalize }},
      'dynos' => {:label => 'Dynos'},
      'workers' => {:label => 'Workers'},
      'git_url' => {:label => 'Git URL'},
      'web_url' => {:label => 'URL', :value => lambda { |url| "<a href='#{url}' target='_blank'>#{url}</a>" }},
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
    @message = 'No apps? Go create some!'
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
