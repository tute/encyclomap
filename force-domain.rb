require 'rack'

class Rack::ForceDomain
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    if request.host =~ /www.encyclomap.com/
      @app.call(env)
    else
      [301, { 'Content-Type' => 'text/html', 'Location' => 'http://www.encyclomap.com' }, []]
    end
  end
end
