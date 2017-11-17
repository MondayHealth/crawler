module Selenium
  module WebDriver
    def for_firefox_with_proxy
      caps = Selenium::WebDriver::Remote::Capabilities.firefox

      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.secure_ssl = false
      profile.assume_untrusted_certificate_issuer = false
      caps.firefox_profile = profile
      
      proxy = Selenium::WebDriver::Proxy.new
      proxy.http = ENV['POLIPO_PROXY']
      proxy.ftp = ENV['POLIPO_PROXY']
      proxy.ssl = ENV['POLIPO_PROXY']
      caps.proxy = proxy
      caps['acceptInsecureCerts'] = true

      client = Selenium::WebDriver::Remote::Http::Default.new
      client.read_timeout = 180

      @Selenium::WebDriver.for :firefox, desired_capabilities: caps, http_client: client
    end
    module_function :for_firefox_with_proxy
  end
end