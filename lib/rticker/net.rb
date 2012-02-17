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

    def self.detect_system_proxy ()
      require 'rbconfig'
      os = Config::CONFIG['host_os']
      # Only support mac os x right now
      return detect_system_proxy_macosx() if os.start_with? "darwin"
      return nil
    end

    def self.detect_system_proxy_macosx ()
      ethernet_enabled = (not %x[networksetup -getinfo ethernet].match(/IP address:/).nil?)
      airport_enabled = (not %x[networksetup -getinfo airport].match(/IP address:/).nil?)
      return nil if not (ethernet_enabled or airport_enabled)
      networkservice = ethernet_enabled ? "ethernet" : "airport"
      webproxy_info = %x[networksetup -getwebproxy #{networkservice}]
      return nil if webproxy_info.match(/Enabled: Yes/).nil?
      host, port, authentication_required = "", "", false
      host = webproxy_info.match(/Server: ([^\n]*)/)[1]
      port = webproxy_info.match(/Port: ([^\n]*)/)[1]
      authentication_required = webproxy_info.match(/Authenticated Proxy Enabled: (0|1)/)[1] == "1"
      return {:host => host, :port => port, :authentication_required => authentication_required}
    end
  end
end
