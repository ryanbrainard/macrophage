$LOAD_PATH << './lib'

require 'sinatra'
require 'sinatra/base'
require 'rack-flash'
require 'heroku-api'

require 'macrophage/pages'
require 'macrophage/web'
require 'macrophage/version'
