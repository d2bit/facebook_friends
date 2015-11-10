require "base64"
require "openssl"
require "json"

class FacebookConnect
  # Some snippets were copied from the omniauth-facebook gem
  # https://github.com/mkdynamic/omniauth-facebook/blob/master/lib/omniauth/strategies/facebook.rb

  FACEBOOK_ID = ENV['FACEBOOK_ID']
  FACEBOOK_SECRET = ENV['FACEBOOK_SECRET']

  def initialize(cookies)
    cookie = cookies["fbsr_#{FACEBOOK_ID}"]
    @access_token = get_access_token(cookie)
  end

  def get_user_info
    fields = 'fields=name,email'
    data_response = fb_get("/me?#{@access_token}&#{fields}")
    return {} unless Net::HTTPOK === data_response

    data_response = JSON.parse(data_response.body)
    {
      name: data_response['name'],
      email: data_response['email']
    }
  end

  def get_friends_info
    paging = 'limit=10'
    data_response = fb_get("/me/friends?#{@access_token}&#{paging}")
    return {} unless Net::HTTPOK === data_response

    data_response = JSON.parse(data_response.body)

    data_response['data'].sort_by { |fb_friend| fb_friend['name'] }
  end

  private

  def fb_get(path)
    Net::HTTP.new('graph.facebook.com', 443)
      .tap { |http| http.use_ssl = true }
      .request(Net::HTTP::Get.new(path))
  end

  def get_access_token(cookie_value)
    return false unless cookie_value.present?
    signature, encoded_payload = cookie_value.split('.')

    decoded_hex_signature = base64_decode_url(signature)
    decoded_payload = JSON.parse(base64_decode_url(encoded_payload))
    query_params = {
      client_id: FACEBOOK_ID,
      client_secret: FACEBOOK_SECRET,
      redirect_uri: "",
      code: decoded_payload["code"]
    }.to_query

    fb_get("/oauth/access_token?#{query_params}").body
  end

  def base64_decode_url(value)
    value += '=' * (4 - value.size.modulo(4))
    Base64.decode64(value.tr('-_', '+/'))
  end

  def valid_signature?(signature, payload, algorithm = OpenSSL::Digest::SHA256.new)
    OpenSSL::HMAC.digest(algorithm, FACEBOOK_SECRET, payload) == signature
  end
end
