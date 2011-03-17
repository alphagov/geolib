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
    
    def method_missing(method, *args, &block)
      if valid_mapit_methods.include?(method)
        Method.new(method.to_s,args).call(@base)
      else
        super(method, *args, &block)
      end
    end

  end
end
