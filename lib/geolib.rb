$:.unshift(File.dirname(__FILE__))

require 'geolib/open_street_map'
require 'geolib/geonames'
require 'geolib/google'
require 'geolib/mapit'
require 'geolib/utils'

require 'json'

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

  def self.gazetteer
    Geolib::Mapit.new()
  end

  def self.ip_locator
    Geolib::Hostip.new()
  end

  class FuzzyPoint
    accuracies = [:point,:postcode,:ward,:council,:nation,:country]
    attr_reader :lon, :lat, :accuracy

    def initialize(lon,lat,accuracy)
      raise ValueError unless accuracies.include?(accuracy)
      @lon,@lat,@accuracy = lon, lat, accuracy
    end

    def to_json
      {:lat=>lat,:lon=>lon,:accuracy=>accuracy}.to_json
    end
  end

  class GeoStack

    attr_accessor :point,:postcode,:ward,:council,:nation,:country,:wmc
    attr_accessor :fuzzy_point

    def initialize(fields)
      # first time we create something, we might
      # well only have the ip_address
      if fields[:ip_address]
        # do something
      end
    end

    def self.from_hash(json)
      # do something
    end

    def to_hash
      {
        :fuzzy_point => {:lat=>51,:lon=>0,:accuracy=>:postcode}
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

end

 

