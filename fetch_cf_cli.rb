require 'sinatra/base'

class FetchCfCli < Sinatra::Base
  get '/' do
    'Hello World from FetchCfCli in separate file!'
  end
end
