class DescribeAround < Sinatra::Base
  get '/' do
    haml :index, format: :html5
  end

  get '/app.js' do
    content_type 'text/javascript'
    coffee :app, no_wrap: true
  end
end
