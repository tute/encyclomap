class DescribeAround < Sinatra::Base
  get '/' do
    erb :index
  end

  get '/app.js' do
    content_type 'text/javascript'
    coffee :app, no_wrap: true
  end
end
