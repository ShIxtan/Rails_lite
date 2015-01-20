 require 'uri'


class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  #
  # You haven't done routing yet; but assume route params will be
  # passed in as a hash to `Params.new` as below:
  def initialize(req, route_params = {})
    @params = route_params
    if req.query_string
      @params.merge!(parse_www_encoded_form(req.query_string))
    end
    if req.body
      @params.merge!(parse_www_encoded_form(req.body))
    end
  end

  def [](key)
    @params[key]
  end

  def to_s
    string = ""
    @params.each_key { |key| string += "#{key}:#{@params[key]}"}
    string
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    pairs = URI::decode_www_form(www_encoded_form)
    result = {}
    pairs.each do |pair|
      hash = pair.last
      parse_key(pair.first).reverse.each do |key|
        hash = { key.to_sym => hash }
      end
      result = deep_merge(result, hash)
    end

    result
  end

  def deep_merge(hash1, hash2)
    hash1.merge(hash2) do |key, val1, val2|
      deep_merge(val1, val2)
    end
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.split(/\]\[|\[|\]/).map(&:to_sym)
  end
end
