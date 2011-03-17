module Geolib
  class Geonames
      def initialize(username = "alphagov", url = "http://api.geonames.org")
          @url = url
          @username = username
      end

      def query(method,params)
        params = {"username"=>@username}.merge(params)
        Geolib.get_json("#{@url}/#{method}?"+Geolib.hash_to_params(params))
      end

      def nearest_place_name(lat,lon)
        params = { "lat" => lat, "lng" => lon}
        results = query("findNearbyPlaceNameJSON",params)
        if results
          return results["geonames"][0]["name"]
        else
          return nil
        end
      end

      def centre_of_country(country_code)
        params = { "country" => country_code, "type" => "JSON" }
        results = query("countryInfo",params)
        if results && results["geonames"]
          country = results["geonames"][0]
          bbe, bbw = country["bBoxEast"],country["bBoxWest"]
          bbn, bbs = country["bBoxNorth"],country["bBoxSouth"]
          lon,lat = (bbe.to_f+bbw.to_f)/2,(bbn.to_f+bbs.to_f)/2
          return { "lat" => lat, "lon" => lon }
        else
          return nil
        end
      end

      def lat_lon_to_country(lat,lon)
        params = { "lat" => lat, "lng" => lon, 'type'=>"JSON"}
        results = query("countryCode",params)
        if results && results["countryCode"]
          return results["countryCode"]
        else
          return nil
        end
      end
  end

end
