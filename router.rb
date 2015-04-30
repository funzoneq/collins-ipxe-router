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

def get_ipv6_type (nodeclass)
  if nodeclass == "loadbalancer"
    1
  elsif nodeclass == "edge"
    2
  elsif nodeclass == "cache"
    3
  elsif nodeclass == "smallobj"
    4
  elsif nodeclass == "dns"
    5
  elsif nodeclass == "stats"
    6
  elsif nodeclass == "util"
    7
  else
    99
  end
end

def hostname_to_ipv6 (hostname)
  hostname[-3,3].to_i
end

def get_ipv6_address (prefix, nodeclass, hostname)
  type = get_ipv6_type(nodeclass)
  host = hostname_to_ipv6(hostname)
  "#{prefix}:#{type}:#{host}:1"
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
      vars[:collins]      = client

      bond0               = asset.public_address
      bond1               = asset.backend_address
      aliasses            = asset.addresses.delete_if { |a| a.is_private? or a.address == bond0.address }

      vars[:asset]        = asset
      vars[:hostname]     = get_hostname(asset.hostname)
      vars[:domain]       = get_domain(asset.hostname)
      vars[:passwd_hash]  = generate_shadow_hash(SecureRandom.hex, vars[:initial_pass])
      vars[:bond0]        = bond0
      vars[:bond1]        = bond1
      vars[:aliasses]     = aliasses
  
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
      vars[:collins]      = client

      bond0               = asset.public_address
      bond1               = asset.backend_address
      aliasses            = asset.addresses.delete_if { |a| a.is_private? or a.address == bond0.address }

      vars[:asset]        = asset
      vars[:hostname]     = get_hostname(asset.hostname)
      vars[:domain]       = get_domain(asset.hostname)
      vars[:passwd_hash]  = generate_shadow_hash(SecureRandom.hex, vars[:initial_pass])
      vars[:bond0]        = bond0
      vars[:bond1]        = bond1
      vars[:aliasses]     = aliasses
  
      erb :preseed, :locals => vars, :content_type => 'text/plain;charset=utf-8'
    rescue => e
      puts "Something went wrong."
      puts e.message
      puts e.backtrace.inspect
    end
  end
end

get '/postinstall/:tag' do
  tag   = URI.unescape(params[:tag])
  asset = client.get(tag)

  if asset.nil?
    vars[:message] = "Asset not found"
    
    erb :error, :locals => vars, :content_type => 'text/plain;charset=utf-8'
  else
    begin
      vars[:collins]      = client

      bond0               = asset.public_address
      bond1               = asset.backend_address
      aliasses            = asset.addresses.delete_if { |a| a.is_private? or a.address == bond0.address }

      vars[:asset]        = asset
      vars[:hostname]     = get_hostname(asset.hostname)
      vars[:domain]       = get_domain(asset.hostname)
      vars[:passwd_hash]  = generate_shadow_hash(SecureRandom.hex, vars[:initial_pass])
      vars[:bond0]        = bond0
      vars[:bond1]        = bond1
      vars[:aliasses]     = aliasses
      vars[:ipv6_prefix]  = asset.prefix
      vars[:ipv6_address] = get_ipv6_address(asset.prefix, asset.nodeclass, vars[:hostname])
  
      erb :postinstall, :locals => vars, :content_type => 'text/plain;charset=utf-8'
    rescue => e
      puts "Something went wrong."
      puts e.message
      puts e.backtrace.inspect
    end
  end
end