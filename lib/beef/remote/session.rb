module BeEF
module Remote

class Session
  
  require 'net/http'
  require 'rubygems'
  require 'json'
  require 'hpricot'
  require 'open-uri'

  attr_reader :cookie
  attr_reader :baseuri
  attr_reader :connected
  attr_reader :nonce
  
  def authenticate(baseuri,username,password)
    self.baseuri = baseuri
    url = self.baseuri+"/ui/authentication/login"
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host,uri.port)
    if uri.scheme.eql? 'https'
      http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req = Net::HTTP::Post.new(URI.parse(url))
    req.body = "username-cfrm=#{username}&password-cfrm=#{password}"
    resp = http.request(req)
    
    if resp.body == "{ success : true }"
      self.cookie = resp.response['set-cookie']
      
      #Get the nonce
      doc = Hpricot(self.getraw("/ui/panel").body)
      self.nonce = doc.at("input#nonce")[:value]
      self.connected = true
    else
      return nil
    end
  end
  
  def getraw(req,opts = nil)
    url = self.baseuri + req
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host,uri.port)
    if uri.scheme.eql? 'https'
      http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    if not opts.nil?
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(opts)
    else
      request = Net::HTTP::Get.new(uri.request_uri)
    end
    request.initialize_http_header({"Cookie" => self.cookie})
    response = http.request(request)
  end
  
  def getjson(req,opts = nil)
    JSON.parse(self.getraw(req,opts).body)
  end
  
  def initialize
    self.cookie = nil
    self.baseuri = nil
    self.connected = nil
  end
  
  def disconnect
    self.cookie = nil
    self.connected = nil
    self.baseuri = nil
  end
    
  private
  
  attr_writer :cookie
  attr_writer :baseuri
  attr_writer :connected
  attr_writer :nonce

end
end
end
