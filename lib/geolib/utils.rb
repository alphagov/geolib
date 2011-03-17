require 'json'
require 'net/http'

module Geolib
  
  def self.get(url)
    url = URI.parse(url) unless url.is_a? URI
    puts url.request_uri
    response = Net::HTTP.start(url.host, url.port) { |http|
      request = Net::HTTP::Get.new(url.request_uri)
      http.request(request)
    }
    return nil if response.code != '200'
    return response.body
  end

  def self.get_json(url)
    response = self.get(url)
    if response
      return JSON.parse(response)
    else
      return nil
    end
  end

  def self.hash_to_params(hash)
    hash.map { |k,v| CGI.escape(k.to_s) + "=" + CGI.escape(v.to_s) }.join("&")
  end

end
