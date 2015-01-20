require 'json'
require 'webrick'


class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    req.cookies.each do |cookie|
      if cookie.name == '_rails_lite_app'
        @cookie = JSON.parse(cookie.value)
        return
      end
    end
    @cookie = {}
  end

  def [](key)
    @cookie[key.to_s]
  end

  def []=(key, val)
    @cookie[key.to_s] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_app', @cookie.to_json)
  end
end

class Flash
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @cookie = {}
    @now = {}
    req.cookies.each do |cookie|
      if cookie.name == '_rails_lite_flash'
        @now = JSON.parse(cookie.value)
      end
    end
  end

  def [](key)
    @now[key.to_s]
  end

  def []=(key, val)
    @cookie[key.to_s] = val
  end

  def now
    @now
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_flash(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_flash', @cookie.to_json)
  end
end
