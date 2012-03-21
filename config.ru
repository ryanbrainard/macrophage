$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'macrophage'
STDOUT.sync = true

run Macrophage::Web