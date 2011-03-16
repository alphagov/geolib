$:.unshift(File.dirname(__FILE__))

require 'geolib/open_street_map'
require 'geolib/geonames'
require 'geolib/google'
require 'geolib/mapit'
require 'geolib/utils'

module Geolib

  def self.map(provider,*args)
    if provider == :openstreetmap
      Geolib::OpenStreetMap.new()
    else
      Geolib::Google.new()
    end
  end

  def self.locations
    Geolib::Geonames.new()
  end

  def self.geo_stack
    Geolib::Mapit.new()
  end

  def self.ip_locator
    Geolib::Hostip.new()
  end

end

 

