require_relative './url_helper'

class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name, :regex, :prefix

  def initialize(pattern, http_method, controller_class, action_name)
    @action_name = action_name
    @controller_class = controller_class
    @http_method = http_method
    @pattern = pattern
    @regex = generate_regex(pattern)
    @prefix = generate_prefix(pattern)
  end

  def generate_regex(pattern)
    # "/cats/:cat_id/statuses" =>
    # "^/cats/(?<cat_id>\\d+)/statuses$"
     parts = pattern.split("/")
     parts.map! do |part|
       if part.start_with?(":")
         "(?<" + part[1..-1] + ">\\d+)"
       else
         part
       end
     end

     Regexp.new("^" + parts.join("/") + "$")
  end

  def generate_prefix(pattern)
    parts = pattern.split("/")
    names = parts.reject do |part|
      part.start_with?(":")
    end
    names[1..-1].join("_")
  end

  def to_s
    "prefix: #{prefix} \n pattern: #{pattern} \n method: #{http_method} \n action: #{controller_class}##{action_name}"
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    return false if req.request_method.downcase.to_s != self.http_method.to_s
    return false unless req.path =~ self.regex
    true
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    match_data = regex.match(req.path)
    url_params = {}
    if match_data
      match_data.names.each do |name|
        url_params[name.to_sym] = Integer(match_data[name])
      end
    end
    controller = controller_class.new(req, res, url_params)
    controller.invoke_action(action_name)
  end
end

class Router
  include Singleton

  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.find { |route| route.matches?(req)}
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    route = match(req)
    if route
      route.run(req, res)
    else
      res.status = 404
    end
  end
end
