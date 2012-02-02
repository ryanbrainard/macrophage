require 'sinatra'
require 'heroku-api'
require './lib/macrophage/pages'

enable :sessions

post '/apps' do
  output = ""
  heroku = Heroku::API.new(:api_key => session[:api_key])
  appAction = params[:action]
  params.each do |param|
    if param[0].match(/^actionable\//)
      appName =  param[0].split('/')[1]

      if appAction == 'delete'
        begin
          heroku.delete_app(appName)
          output << "<p>Deleted #{appName}</p>"
        rescue
          output << "<p>Failed to delete #{appName}</p>"
        end
      end
    end
  end
  output
end

get '/apps' do
  heroku = Heroku::API.new(:api_key => session[:api_key])

  apps = heroku.get_apps.body

  output = "<form method='post'>"
  #output << "<input type='submit' name='action' value='view'>"
  output << "<input type='submit' name='action' value='delete'>"
  output << "<table border='1'>"

  output << "<tr><th>Action</th>"
  apps[0].each { |header| output << "<th>#{header[0]}</th>" }
  output << "</tr>"

  apps.each do |app|
    output << "<tr><td><input type='checkbox' name='actionable/#{app['name']}'/></td>"
    app.each do |prop|
      output << "<td>#{prop[1]}</td>"
    end
    output << "</tr>"
  end
  output << "</table>"
  output << "</form>"
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