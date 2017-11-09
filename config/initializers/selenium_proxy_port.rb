module Selenium
  module WebDriver
    class Proxy

      # Seleniuum bug workaround from https://github.com/mozilla/geckodriver/issues/764
      def as_json(*)
        http_proxy, http_proxy_port = split_port_if_found(http)
        ftp_proxy, ftp_proxy_port = split_port_if_found(ftp)
        ssl_proxy, ssl_proxy_port = split_port_if_found(ssl)
        json_result = {
          'proxyType' => TYPES[type],
          'ftpProxy' => ftp_proxy,
          'ftpProxyPort' => ftp_proxy_port,
          'httpProxy' => http_proxy,
          'httpProxyPort' => http_proxy_port,
          'noProxy' => no_proxy,
          'proxyAutoconfigUrl' => pac,
          'sslProxy' => ssl_proxy,
          'sslProxyPort' => ssl_proxy_port,
          'autodetect' => auto_detect,
          'socksProxy' => socks,
          'socksUsername' => socks_username,
          'socksPassword' => socks_password
        }.delete_if { |_k, v| v.nil? }
        
        json_result if json_result.length > 1
      end

      def split_port_if_found proxy_string
        proxy = http
        proxy_port = nil
        if http =~ /:[0-9]+$/
          proxy_port = http.split(":").last.to_i
          proxy = http.split(":").first
        end
        return proxy, proxy_port
      end
    end
  end
end