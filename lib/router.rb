require 'sinatra'
require 'collins_auth'
require 'uri'
require 'yaml'
require 'tilt/erb'
require 'securerandom'

class Router
  def initialize
      @vars   = YAML.load_file 'config.yml'
      @client = Collins::Authenticator.setup_client
  end

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

  def hostname_to_ipv6 (hostname)
    hostname[-3,3].to_i
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

  def parse_rack_position (rack_position)
    regexp = %r{ (?<DC> [\w]+)-(?<RACK> [\w]+)-(?<U> [\w]+) }x
    match = regexp.match(rack_position)
    Hash[ match.names.zip( match.captures ) ]
  end

  def get_ipv6_prefix (client, rack_position)
    position = self.parse_rack_position(rack_position)
    rack = client.get("#{position['DC']}-#{position['RACK']}")
    rack.get_attribute("IPV6_PREFIX")
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
end