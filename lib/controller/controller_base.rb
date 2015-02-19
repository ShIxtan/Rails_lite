require_relative './url_helper'
require_relative './auth_helper'
require_relative './params'
require_relative './session'
require 'active_support/inflector'
require 'erb'
require 'securerandom'


class ControllerBase
  include LinkHelper
  include AuthHelper
  extend UrlHelper

  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = Params.new(req, route_params)
    self.class.add_url_helpers(req)
    if req.request_method != "GET"
      raise "Invalid Token!\n #{params[:authenticity_token]} --- #{form_authenticity_token}" unless form_authenticity_token == params[:authenticity_token]
    end
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    !!@already_built_response
  end

  def render(template_name)
    template = File.read("views/#{self.class.to_s.underscore}/#{template_name}.html.erb")
    result = ERB.new(template).result(binding)
    render_content(result, "text/html")
  end

  # Set the response status code and header
  def redirect_to(url)
    prepare_response
    @res.status = 302
    @res.header['location'] = url
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, type)
    prepare_response
    @res.content_type = type
    @res.body = content
  end

  def prepare_response
    raise "Already Built Response" if already_built_response?
    @already_built_response = true
    flash.store_flash(res)
    session.store_session(res)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    send(name)
    render(name) unless already_built_response?
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  def flash
    @flash ||= Flash.new(req)
  end
end
