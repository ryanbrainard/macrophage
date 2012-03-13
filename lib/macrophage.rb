$LOAD_PATH << './lib'

require 'sinatra'
require 'sinatra/base'
require 'rack-flash'
require 'heroku-api'

require 'macrophage/pages'

require 'macrophage/base_action'
require 'macrophage/delete_action'
require 'macrophage/maintenance_on_action'
require 'macrophage/maintenance_off_action'

require 'macrophage/web'
require 'macrophage/version'
