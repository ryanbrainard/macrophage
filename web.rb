require 'sinatra'
require 'heroku-api'
require './lib/macrophage/pages'

enable :sessions

post '/apps' do
  heroku = Heroku::API.new(:api_key => session[:api_key])
  appAction = params[:action]
  params.each do |param|
    if param[0].match(/^actionable\//)
      appName =  param[0].split('/')[1]

      if appAction == 'delete'
        begin
          heroku.delete_app(appName)
          @message = "Deleted #{appName}"
        rescue
          @message = "Failed to delete #{appName}"
        end
      end
    end
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