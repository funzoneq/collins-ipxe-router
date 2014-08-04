require 'sinatra'
require 'collins_auth'
require 'uri'
require 'yaml'

def provision? (asset)
  asset.status == "Provisioning"
end

def testing? (asset)
  asset.omw_test == "true"
end

def get_hostname (hostname)
  hostname.split(".").shift
end

def get_domain (hostname)
  domain = hostname.split(".")
  domain.shift
  domain
end

get '/pxe/:mac' do
  mac             = URI.unescape(params[:mac])
  vars            = YAML.load_file 'config.yml'
  client          = Collins::Authenticator.setup_client
  asset           = client.find({:mac_address => mac, :details => true, :size => 1}).first
  vars[:asset]    = asset unless asset.nil?
  vars[:hostname] = get_hostname(asset.hostname) unless asset.nil?
  vars[:domain]   = get_domain(asset.hostname) unless asset.nil?
  
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

get '/kickstart/:mac' do
  mac             = URI.unescape(params[:mac])
  vars            = YAML.load_file 'config.yml'
  client          = Collins::Authenticator.setup_client
  asset           = client.find({:mac_address => mac, :details => true, :size => 1}).first
  
  if asset.nil?
    vars[:message] = "Asset not found"
    
    erb :error, :locals => vars, :content_type => 'text/plain;charset=utf-8'
  else
    vars[:collins]  = client unless client.nil?
    vars[:asset]    = asset unless asset.nil?
    vars[:hostname] = get_hostname(asset.hostname) unless asset.nil?
    vars[:domain]   = get_domain(asset.hostname) unless asset.nil?
  
    erb :kickstart, :locals => vars, :content_type => 'text/plain;charset=utf-8'
  end
end