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
  
  # I think we could do this with mattr_ in rails
  # but I'll do it manually to avoid having to 
  # depend on activesupport
  [ :default_geolib_provider,
    :default_map_provider, 
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
  
  # We have to do this after the accessors are defined as a new mapit instance
  # now depends on the existence of Geolib.default_geolib_provider
  @@default_geolib_provider = "http://mapit.mysociety.org"
  @@default_map_provider = caching(OpenStreetMap.new())
  @@default_locations    = caching(Geonames.new())
  @@default_ip_mapper    = caching(Hostip.new())
  @@default_gazeteer = caching(Mapit.new())

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


  def centre_of_country(country_code)
    default_locations.centre_of_country(country_code)
  end

  def centre_of_district(district_postcode)
    default_gazeteer.centre_of_district(district_postcode)
  end

  def areas_for_stack_from_postcode(postcode)
    default_gazeteer.areas_for_stack_from_postcode(postcode)
  end
  
  def areas_for_stack_from_coords(lat, lon)
    default_gazeteer.areas_for_stack_from_coords(lat, lon)
  end
  
  def lat_lon_from_postcode(postcode)
    areas = default_gazeteer.areas_for_stack_from_postcode(postcode)
    areas[:point]
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
    ACCURACIES = [:point,:postcode,:postcode_district,:ward,:council,:nation,:country,:planet]
    attr_reader :lon, :lat, :accuracy


    def initialize(lat,lon,accuracy)
      accuracy = accuracy.to_sym
      raise ValueError unless ACCURACIES.include?(accuracy)
      @lon,@lat,@accuracy = lon.to_f, lat.to_f, accuracy
      if @accuracy == :point
        @lon = @lon.round(2)
        @lat = @lat.round(2)
      end
    end

    def to_hash
      {"lon"=> self.lon.to_s,"lat"=>self.lat.to_s,"accuracy"=>accuracy.to_s}
    end
  end

  class GeoStack

    attr_accessor :postcode,:ward,:council,:nation,:country,:wmc,:lat,:lon
    attr_accessor :fuzzy_point
    attr_accessor :friendly_name

    def initialize()
      yield self
    end

    def calculate_fuzzy_point
      if self.lat and self.lon
        return FuzzyPoint.new(self.lat, self.lon, :point)
      end
      
      if self.postcode
        district = postcode.split(" ")[0]
        district_centre = Geolib.centre_of_district(district)
        if district_centre
          return FuzzyPoint.new(district_centre["lat"],district_centre["lon"],:postcode_district)
        end
      end

      if self.country
        country_centre = Geolib.centre_of_country(self.country)
        if country_centre
          return FuzzyPoint.new(country_centre["lat"],country_centre["lon"],:country)
        end
      end

      FuzzyPoint.new(0,0,:planet)
    end

    def self.new_from_ip(ip_address)
      remote_location = Geolib.remote_location(ip_address)
      new() do |gs|
        if remote_location
          gs.country = remote_location['country']
        end
        gs.fuzzy_point = gs.calculate_fuzzy_point
      end
    end

    def self.new_from_hash(hash)
      new() do |gs|
        gs.set_fields(hash)
        unless hash['fuzzy_point']
          raise ArgumentError, "fuzzy point required"
        end
      end
    end

    def to_hash
      {
        :fuzzy_point => self.fuzzy_point.to_hash,
        :postcode => self.postcode,
        :ward => self.ward,
        :council => self.council,
        :nation => self.nation,
        :country => self.country,
        :wmc => self.wmc,
        :friendly_name => self.friendly_name
      }.select {|k,v| !(v.nil?) }
    end

    def update(hash)
      self.class.new() do |empty|
        full_postcode = hash['postcode']
        empty.set_fields(hash)
        if has_valid_lat_lon(hash) 
          empty.fetch_missing_fields_for_coords(hash['lat'], hash['lon'])
        elsif full_postcode
          empty.fetch_missing_fields_for_postcode(full_postcode)
        end
        empty.fuzzy_point = empty.calculate_fuzzy_point
      end
    end

    def has_valid_lat_lon(hash)
       return (hash['lon'] and hash['lat'] and hash['lon'] != "" and hash['lat'] != "")
    end

    def fetch_missing_fields_for_postcode(postcode)
      if matches = postcode.match(POSTCODE_REGEXP)
        self.country = "UK"
        fields = Geolib.areas_for_stack_from_postcode(postcode)
        if fields
          lat_lon = fields[:point]
          if lat_lon
            self.friendly_name = Geolib.nearest_place_name(lat_lon['lat'],lat_lon['lon'])
          end
          set_fields(fields.select {|k,v| k != :point})
        end
      end
    end
    
    def fetch_missing_fields_for_coords(lat, lon)
      self.friendly_name = Geolib.nearest_place_name(lat, lon)
      fields = Geolib.areas_for_stack_from_coords(lat, lon)
      if ['England', 'Scotland', 'Northern Ireland', 'Wales'].include?(fields[:nation])
        self.country = 'UK'
        set_fields(fields.select {|k,v| k != :point})
      end
    end

    def set_fields(hash)
      hash.each do |geo, value|
        setter = (geo.to_s+"=").to_sym
        if self.respond_to?(setter)
          unless value == ""
            self.send(setter,value)
          end
        else
          raise ArgumentError, "geo type '#{geo}' is not a valid geo type"
        end
      end
      self
    end

    def fuzzy_point=(point)
      if point.is_a?(Hash)
        @fuzzy_point = FuzzyPoint.new(point["lat"],point["lon"],point["accuracy"])
      else
        @fuzzy_point = point
      end
    end

    POSTCODE_REGEXP = /([A-Z]{1,2}[0-9R][0-9A-Z]?)\s*([0-9])[ABD-HJLNP-UW-Z]{2}/i
    SECTOR_POSTCODE_REGEXP =  /([A-Z]{1,2}[0-9R][0-9A-Z]?)\s*([0-9])/i

    def postcode=(postcode)
      if (matches = (postcode.match(POSTCODE_REGEXP) || postcode.match(SECTOR_POSTCODE_REGEXP)))
        @postcode = matches[1]+" "+matches[2]
      end
    end


  end

  extend self
    
end

 

