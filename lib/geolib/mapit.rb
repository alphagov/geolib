require 'cgi'
require 'uri'

module Geolib

  class Mapit
    
    class Method
      def initialize(url,params = [])
        @url = url
        @params = params
      end

      def to_url(base_url)
        url = "/#{@url}" unless /^\//.match(@url)
        params = @params.map {|p| 
          p = p.join(",") if p.is_a?(Array) 
          CGI::escape(p)
        }
        url_path = "#{base_url}#{url}"
        url_path += "/#{params.join("/")}" if params.length > 0
        return url_path
      end

      def call(base_url)
        Geolib.get_json(self.to_url(base_url))  
      end
    end

    def initialize(base="http://mapit.mysociety.org")
      @base = base
    end

    def valid_mapit_methods
      [:postcode,:areas,:area,:point,:generations]
    end

    def respond_to?(sym)
      valid_mapit_methods.include?(sym) || super(sym)
    end
   
    def areas_for_stack_from_postcode(postcode)
      query = self.postcode(postcode)
      results = {}
      if query
        query['shortcuts'].each do |typ,id|
          results[typ.downcase.to_sym] = query['areas'][id.to_s].select {|k,v| ["name","id","type"].include?(k) }
          results[:nation] = query['areas'][id.to_s]['country_name'] if results[:nation].nil?
        end
        lat,lon = query['wgs84_lat'],query['wgs84_lon']
        results[:point] = {'lat' => lat, 'lon' => lon}
      end
      return results
    end

    def centre_of_district(district_postcode)
      query = self.postcode("partial",district_postcode)
      if query
        lat,lon = query['wgs84_lat'],query['wgs84_lon']
        return {'lat' => lat, 'lon' => lon}
      end
    end

    def method_missing(method, *args, &block)
      if valid_mapit_methods.include?(method)
        Mapit::Method.new(method.to_s,args).call(@base)
      else
        super(method, *args, &block)
      end
    end

  end
end
