require 'sinatra'
require 'collins_auth'
require 'uri'
require 'yaml'
require 'tilt/erb'
require 'securerandom'

vars   = YAML.load_file 'config.yml'
client = Collins::Authenticator.setup_client

def provision? (asset)
  asset.status == "Provisioning"
end

def testing? (asset)
  asset.omw_test == "true"
end

def reintake? (asset)
  asset.reintake == "true"
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

def generate_shadow_hash (salt, passwd)
  passwd.crypt('$6$' + salt);
end

get '/pxe/:mac' do
  mac             = URI.unescape(params[:mac])
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
  when reintake?(asset)
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
  asset           = client.find({:mac_address => mac, :details => true, :size => 1}).first

  if asset.nil?
    vars[:message] = "Asset not found"
    
    erb :error, :locals => vars, :content_type => 'text/plain;charset=utf-8'
  else
    begin
      vars[:collins]  = client unless client.nil?

      if not asset.nil?
        bond0               = asset.public_address
        bond1               = asset.backend_address
        aliasses            = asset.addresses.delete_if { |a| a.is_private? or a.address == bond0.address }

        vars[:asset]        = asset
        vars[:hostname]     = get_hostname(asset.hostname)
        vars[:domain]       = get_domain(asset.hostname)
        vars[:passwd_hash]  = generate_shadow_hash(SecureRandom.hex, passwd)
        vars[:bond0]        = bond0
        vars[:bond1]        = bond1
        vars[:aliasses]     = aliasses
      end
  
      erb :kickstart, :locals => vars, :content_type => 'text/plain;charset=utf-8'
    rescue => e
      puts "Something went wrong."
      puts e.message
      puts e.backtrace.inspect
    end
  end
end

get '/preseed/:mac' do
  mac             = URI.unescape(params[:mac])
  asset           = client.find({:mac_address => mac, :details => true, :size => 1}).first

  if asset.nil?
    vars[:message] = "Asset not found"
    
    erb :error, :locals => vars, :content_type => 'text/plain;charset=utf-8'
  else
    begin
      vars[:collins]  = client unless client.nil?

      if not asset.nil?
        bond0               = asset.public_address
        bond1               = asset.backend_address
        aliasses            = asset.addresses.delete_if { |a| a.is_private? or a.address == bond0.address }

        vars[:asset]        = asset
        vars[:hostname]     = get_hostname(asset.hostname)
        vars[:domain]       = get_domain(asset.hostname)
        vars[:passwd_hash]  = generate_shadow_hash(SecureRandom.hex, passwd)
        vars[:bond0]        = bond0
        vars[:bond1]        = bond1
        vars[:aliasses]     = aliasses
      end
  
      erb :preseed, :locals => vars, :content_type => 'text/plain;charset=utf-8'
    rescue => e
      puts "Something went wrong."
      puts e.message
      puts e.backtrace.inspect
    end
  end
end