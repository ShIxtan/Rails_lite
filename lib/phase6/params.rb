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
      @params = @params.merge(parse_www_encoded_form(req.query_string))
    end
    if req.body
      @params = @params.merge(parse_www_encoded_form(req.body))
    end
  end

  def [](key)
    @params[key.to_s]
  end

  def to_s
    @params.to_json.to_s
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
    params = {}
    pairs.each do |pair|
      hash = pair.last
      parse_key(pair.first).reverse.each do |key|
        hash = {key.to_s => hash}
      end
      params = deep_merge(params, hash)
    end

    params
  end

  def deep_merge(hash1, hash2)
    hash1.merge(hash2) { |key, val1, val2| deep_merge(val1, val2)}
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.split(/\]\[|\[|\]/)
  end
end
