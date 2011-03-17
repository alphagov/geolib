$:.unshift(File.dirname(__FILE__))

require 'geolib/open_street_map'
require 'geolib/geonames'
require 'geolib/google'
require 'geolib/mapit'
require 'geolib/utils'
require 'geolib/hostip'
require 'geolib/lru_cache'

module Geolib

  def self.caching(obj)
    # this is too simple to really help us much,
    # we should probably be using memcache or redis
    return SimpleCache.new(obj)
  end

  @@default_map_provider = caching(OpenStreetMap.new())
  @@default_locations    = caching(Geonames.new())
  @@default_ip_mapper    = caching(Hostip.new())
  @@default_gazeteer     = caching(Mapit.new())

  # I think we could do this with mattr_ in rails
  # but I'll do it manually to avoid having to 
  # depend on activesupport
  [ :default_map_provider, 
    :default_locations, 
    :default_ip_mapper, 
    :default_gazeteer].each do |sym|
    
    class_eval <<-EOS, __FILE__, __LINE__
      def self.#{sym}
        @@#{sym}
      end

      def self.#{sym}=(obj,cache=true)
        obj = caching(obj) if cache
        @@#{sym} = obj
      end
    EOS
  end

  # Given a latitude and longitude, return
  # a place name appropriate for displaying to
  # the user, for example:
  # 
  # nearest_place_name(51.476,0) might return "Greenwich"
  #
  def nearest_place_name(lat,lon)
    default_locations.nearest_place_name(lat,lon)
  end

  # Return an iso country code for a given lat, lon
  def lat_lon_to_country(lat,lon)
    default_locations.lat_lon_to_country(lat,lon)
  end


  def map_provider(options)
    provider = options.delete(:provider)
    case provider
    when :openstreetmap
      OpenStreetMap.new()
    when :google
      Google.new()
    else
      default_map_provider
    end
  end
  # Provide the URL for a static map, parameters are normalised
  # between providers:
  # 
  #   :w, :h     - width and height of the image
  #   :z         - zoom level of the image
  #   :marker_lat, :marker_lon - optional marker co-ords
  #
  def map_img(lat,lon,options={})
    map_provider(options).map_img(lat,lon,options)
  end

  # Return a lat/lon pair for a given ip address
  def remote_location(ip_address)
    default_ip_mapper.remote_location(ip_address)
  end

  # Similar to map_img call, but generates a URL
  # to a page containing a map. Also, accepts
  # a provider argument that allows one to specify 
  # different services.
  #
  def map_href(lat,lon,options={})
    map_provider(options).map_href(lat,lon,options)
  end


  class FuzzyPoint
    accuracies = [:point,:postcode,:ward,:council,:nation,:country]
    attr_reader :lon, :lat, :accuracy

    def initialize(lon,lat,accuracy)
      raise ValueError unless accuracies.include?(accuracy)
      @lon,@lat,@accuracy = lon, lat, accuracy
    end

    def to_hash
      {:lat=>lat,:lon=>lon,:accuracy=>accuracy}
    end
  end

  class GeoStack

    attr_accessor :point,:postcode,:ward,:council,:nation,:country,:wmc
    attr_accessor :fuzzy_point

    def initialize()
      # first time we create something, we might
      # well only have the ip_address
      if fields[:ip_address]
        # do something
      end
    end

    def self.new_from_ip(ip_address)
      #
    end

    def self.new_from_hash(json)
      # do something
    end

    def to_hash
      {
        :fuzzy_point => {:lat=>51,:lon=>0,:accuracy=>:postcode},
        :country => "UK",
        :nation  => "E",
        :council => { :id => 2493, :name => "Greenwich Borough Council", :type => "LBO" },
        :ward    => { :id => 8365, :name => "Greenwich West", :type => "LBW" },
        :wmc     => { :id=> 65837, :name => "Greenwich and Woolwich", :type => "WMC" },
        :postcode => "SE10 8UG",
        :point => { :lat=>"51.476441375971447", :lon => "-0.01587542101038760" }
      }
    end

    def new_info_received(fields)
      if fields[:postcode]
        # compare to current info and change if necessary
      end
      return self
    end

  end

  extend self
    
end

 

