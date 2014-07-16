require 'sinatra'
require 'collins_auth'
require 'uri'
require 'yaml'
require 'pp'

def provision? (asset)
  asset.status == "Provisioning"
end

def testing? (asset)
  asset.omw_test == "true"
end

get '/pxe/:mac' do
  vars = {}
  mac = URI.unescape(params[:mac])
  vars = YAML.load_file 'config.yml'
  
  client = Collins::Authenticator.setup_client
  results = client.find({:mac_address => mac, :details => true, :size => 1})
  
  asset = results.first
  
  case
  when asset.nil?
    vars[:action] = :intake
  when testing?(asset)
    vars[:action] = :testing
  when provision?(asset)
    vars[:action] = :provision
  else
    vars[:action] = :boot
  end
  
  erb :ipxe, :locals => vars, :content_type => 'text/plain;charset=utf-8'
end