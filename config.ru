require 'rubygems'
require 'sinatra'

require './router'
set :root, Pathname(__FILE__).dirname
set :environment, :production
set :run, false
run Sinatra::Application