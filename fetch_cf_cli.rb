require 'sinatra/base'
require 'json/pure'
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
    erb :index, format: :html5, layout: false
  end

  # Convert labels like:
  # ["gcf-darwin-amd64.tgz", "gcf-linux-amd64.tgz", "gcf-windows-386.zip", "gcf-windows-amd64.zip"]
  # into names like:
  # ["darwin-amd64", "linux-amd64", "windows-386", "windows-amd64"]
  # and return them as an Array of { name => asset }
  def cli_release_asset_names_to_labels
    cli_release_assets.inject({}) do |result, asset|
      label = asset["label"]
      name = if label =~ /cf-(.*)\.(tgz|zip)/
        $1
      else
        label
      end
      result[name] = asset
      result
    end
  end

  def cli_release_assets
    latest_cli_release["assets"]
  end

  def cli_release_name
    latest_cli_release["name"]
  end

  def latest_cli_release
    cli_releases.first
  end

  def cli_releases
    response = HTTParty.get(cli_releases_uri, cli_releases_headers)
    # response.body, response.code, response.message, response.headers.inspect
    JSON.parse(response.body)
  end

  def cli_releases_uri
    'https://api.github.com/repos/cloudfoundry/cli/releases'
  end

  def cli_releases_headers
    raise "Must set @github_access_token first" unless @github_access_token
    { headers: { "Authorization" => "token #{@github_access_token}", "User-Agent" => "fetch_cf_cli by Dr Nic Williams" } }
  end
end
