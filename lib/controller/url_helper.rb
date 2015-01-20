require_relative './router'

module LinkHelper
  def link_to(name, url)
    html = <<-HTML
    <a href="#{url}">#{name}</a>
    HTML
  end

  def button_to(name, url, method = :post)
    html = <<-HTML
    <form method="#{method}" action="#{url}">
      <input type="submit" value="#{name}">
    </form>
    HTML
  end
end


module UrlHelper
  def add_url_helpers(req)
    Router.instance.routes.each do |route|
      names = route.pattern.split("/")
      varcount = 0
      define_method(route.prefix + "_url") do |*args|
        url = ""
        names.each do |name|
          if name.start_with?(":")
            url += "/#{args[varcount].id}"
            varcount += 1
          else
            url += "/#{name}"
          end
        end
        url[1..-1]
      end
    end
  end
end
