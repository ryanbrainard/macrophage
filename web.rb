require 'sinatra'
require 'heroku-api'

enable :sessions

get '/apps' do
  heroku = Heroku::API.new(:api_key => session[:api_key])

  apps = heroku.get_apps.body

  output = "<table border='1'>"

  output << "<tr>"
  apps[0].each { |header| output << "<th>#{header[0]}</th>" }
  output << "</tr>"

  apps.each do |app|
    output << "<tr>"
    app.each do |prop|
      output << "<td>#{prop[1]}</td>"
    end
    output << "</tr>"
  end
  output << "</table>"
end

get '/login' do
  "<form method='post'>API Key: <input name='api_key'/><input type='submit'/></form>"
end

post '/login' do
  session[:api_key] = params[:api_key]
  redirect "/apps"
end

get '/*' do
  redirect "/login"
end