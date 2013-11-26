require './fetch_cf_cli'

unless github_access_token = ENV['GITHUB_ACCESS_TOKEN']
  $stderr.puts "Please set environment variable $GITHUB_ACCESS_TOKEN"
  $stderr.puts "Create new tokens via https://github.com/settings/applications 'Personal Access Tokens' section"
  exit 1
end

run FetchCfCli.new(github_access_token)
