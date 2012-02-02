require 'sinatra'
require 'heroku-api'
require './lib/macrophage/pages'

enable :sessions

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
  session[:api_key] = params[:api_key]
  redirect "/apps"
end

get '/*' do
  redirect "/login"
end