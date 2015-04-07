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
  if not hostname.nil?
    hostname.split(".").shift
  else
    'foo'
  end
end

def get_domain (hostname)
  if not hostname.nil?  
    domain = hostname.split(".")
    domain.shift
    domain.join(".")
  else
    'example.com'
  end
end

get '/pxe/:mac' do
  mac             = URI.unescape(params[:mac])
  vars            = YAML.load_file 'config.yml'
  client          = Collins::Authenticator.setup_client
  asset           = client.find({:mac_address => mac, :details => true, :size => 1}).first
  vars[:asset]    = asset unless asset.nil?

  if asset.nil?
    vars[:hostname] = 'foo'
    vars[:domain]   = 'example.com'
  else
    vars[:hostname] = get_hostname(asset.hostname)
    vars[:domain]   = get_domain(asset.hostname)
  end
  
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
    begin
      vars[:collins]  = client unless client.nil?
      vars[:asset]    = asset unless asset.nil?
      vars[:hostname] = get_hostname(asset.hostname) unless asset.nil?
      vars[:domain]   = get_domain(asset.hostname) unless asset.nil?
      vars[:bond0]    = asset.public_address unless asset.nil?
      vars[:bond1]    = asset.backend_address unless asset.nil?
      vars[:aliasses] = asset.addresses.delete_if {|a| a.is_private? or a.address == asset.public_address.address } unless asset.nil?
  
      erb :kickstart, :locals => vars, :content_type => 'text/plain;charset=utf-8'
    rescue => e
      puts "Something went wrong."
      puts e.inspect
    end
  end
end