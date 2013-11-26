require 'sinatra/base'
require 'json'
require 'httparty'

class FetchCfCli < Sinatra::Base
  def initialize(*args)
    super
    unless @github_access_token = ENV['GITHUB_ACCESS_TOKEN']
      $stderr.puts "Please set environment variable $GITHUB_ACCESS_TOKEN"
      $stderr.puts "Create new tokens via https://github.com/settings/applications 'Personal Access Tokens' section"
      exit 1
    end
  end

  get '/' do
    content_type :json
    cli_releases
  end


  def cli_releases
    response = HTTParty.get(cli_releases_uri, cli_releases_headers)
    # response.body, response.code, response.message, response.headers.inspect
    response.body
  end

  def cli_releases_uri
    'https://api.github.com/repos/cloudfoundry/cli/releases'
  end

  def cli_releases_headers
    { headers: { "Authorization" => "token #{@github_access_token}", "User-Agent" => "fetch_cf_cli by Dr Nic Williams" } }
  end
end
