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

  async_app_actions = {}
  params.each do |param|
    if param[0].match(/^actionable\//)
      app_name =  param[0].split('/')[1]
      async_app_actions[app_name] = Thread.new do
        case params[:action]
          when 'delete'
            heroku.delete_app(app_name)
            puts "Deleted " << app_name
          else
            raise 'Invalid app action'
        end
      end
    end
  end

  successes = []
  failures = []
  async_app_actions.each do |app_name, action|
    begin
      action.value
      successes << app_name
    rescue
      failures << app_name
    end
  end

  @message = ""
  unless successes.empty?
    @message << "Successfully " << params[:action] << "d " << successes.join(", ")
  end
  unless failures.empty?
    @message << " Failed to " << params[:action] << " " << failures.join(", ")
  end

  @apps = heroku.get_apps.body
  erb :apps
end

get '/apps' do
  heroku = Heroku::API.new(:api_key => session[:api_key])
  @apps = heroku.get_apps.body
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
