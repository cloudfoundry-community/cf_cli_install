require 'sinatra/base'
require 'json/pure'
require 'httparty'

class CfCliInstall < Sinatra::Base
  attr_reader :github_access_token

  def initialize(*args)
    super
    unless @github_access_token = ENV['GITHUB_ACCESS_TOKEN']
      $stderr.puts "Please set environment variable $GITHUB_ACCESS_TOKEN"
      $stderr.puts "Create new tokens via https://github.com/settings/applications 'Personal Access Tokens' section"
      exit 1
    end
  end

  get '/' do
    fetch_latest_release
    erb :index, format: :html5
  end

  get '/release/:os_name/:os_hardware' do
    fetch_latest_release
    os_name = params[:os_name]
    os_hardware = params[:os_hardware]
    os_hardware = "amd64" if os_hardware =~ /64/
    os_hardware = "386" if os_hardware =~ /32/

    asset = cli_release_asset(@cli_release_assets, os_name.downcase, os_hardware)
    redirect to(asset["url"]) if asset
  end

  get '/latest/:os_name/:os_hardware' do
    os_name = params[:os_name].downcase
    os_hardware = params[:os_hardware]
    os_hardware = "amd64" if os_hardware =~ /64/
    os_hardware = "386" if os_hardware =~ /32/
    url = if os_name == "darwin"
      "http://go-cli.s3.amazonaws.com/gcf-darwin-amd64.tgz"
    elsif os_name == "linux"
      if os_hardware == "386"
        "http://go-cli.s3.amazonaws.com/gcf-linux-386.tgz"
      else
        "http://go-cli.s3.amazonaws.com/gcf-linux-amd64.tgz"
      end
    elsif os_name == "windows"
      if os_hardware == "386"
        "http://go-cli.s3.amazonaws.com/gcf-windows-386.zip"
      else
        "http://go-cli.s3.amazonaws.com/gcf-windows-amd64.zip"
      end
    end
    redirect to(url)
  end

  def fetch_latest_release
    latest_cli_release = cli_releases.first
    @cli_release_name = latest_cli_release["name"]
    @cli_release_assets = latest_cli_release["assets"]
  end

  def cli_release_name
    @cli_release_name
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
    raise "Must set @github_access_token first" unless github_access_token
    { headers: { "Authorization" => "token #{github_access_token}", "User-Agent" => "cf_cli_install by Dr Nic Williams" } }
  end

  def request_hostname
    hostname = URI::Generic.build(scheme: request.scheme, host: request.host, port: request.port).to_s
    hostname.gsub(/:80/, '')
  end

  # +platform+ - windows, linux, darwin
  def cli_release_asset(cli_release_assets, platform, arch = "amd64")
    cli_release_assets.find {|asset| asset["name"] =~ /#{platform}-#{arch}/ }
  end

  def cli_name
    "gcf"
  end
end
