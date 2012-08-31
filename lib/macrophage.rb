require 'sinatra'
require 'sinatra/base'
require 'rack-flash'
require 'heroku-api'
require 'rest-client'

require 'macrophage/pages'

require 'macrophage/actions/base_action'
require 'macrophage/actions/delete_action'
require 'macrophage/actions/maintenance_on_action'
require 'macrophage/actions/maintenance_off_action'

require 'macrophage/web'
require 'macrophage/version'
