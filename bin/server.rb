require 'webrick'
require_relative '../lib/controller/controller_base'
require_relative '../lib/controller/router'
require_relative '../lib/model/sql_object'

# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPRequest.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPResponse.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/Cookie.html

class Cat < SQLObject
  self.finalize!
end

class Human < SQLObject
  self.table_name = 'humans'

  self.finalize!
end

class HumansController < ControllerBase
  def index
    @humans = Human.all
  end
end

class CatsController < ControllerBase
  def index
    @cats = Cat.all
    render :index
  end

  def new
    @cat = Cat.new
    render :new
  end

  def show
    @cat = Cat.find(params[:id])
    render :show
  end

  def create
    @cat = Cat.new(name: params[:cat][:name])

    if @cat.save
      redirect_to cat_url(@cat)
    else
      flash.now[:errors] = "can't save that cat"
      render :new
    end
  end
end

router = Router.instance
router.draw do
  get "/cats", CatsController, :index
  get "/new_cat", CatsController, :new
  post "/cats", CatsController, :create
  get "/cat/:id", CatsController, :show
end

server = WEBrick::HTTPServer.new(Port: 3000)
server.mount_proc('/') do |req, res|
  route = router.run(req, res)
end

trap('INT') do
   server.shutdown
   DBConnection.reset
end

DBConnection.reset
server.start
