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
  appAction = params[:action]

  successfully_deleted_apps = []
  failed_deleted_apps = []

  params.each do |param|
    if param[0].match(/^actionable\//)
      app_name =  param[0].split('/')[1]

      if appAction == 'delete'
        begin
          heroku.delete_app(app_name)
          successfully_deleted_apps << app_name
        rescue
          failed_deleted_apps << app_name
        end
      end
    end
  end

  @message = ""
  unless successfully_deleted_apps.empty?
    @message << "Successfully deleted " << successfully_deleted_apps.join(", ")
  end
  unless failed_deleted_apps.empty?
    @message << " Failed to delete " << failed_deleted_apps.join(", ")
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
