require 'net/http'
require 'uri'

module RTicker
  class Net
    
    @@proxy_host = nil
    @@proxy_port = nil

    def self.proxy ()
      return nil if @@proxy_host.nil?
      port = @@proxy_port || 80
      return "#{@@proxy_host}:#{port}"
    end

    def self.proxy= (proxy)
      host, port = proxy.split(":")
      @@proxy_host = host
      @@proxy_port = port || 80
    end

    def self.get_response (url)
      begin
        return ::Net::HTTP::Proxy(@@proxy_host, @@proxy_port).get(URI.parse url)
      rescue Timeout::Error => e
        return ""
      end
    end
  end
end
