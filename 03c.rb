# frozen_string_literal: true

require 'oauth2'
require 'base64'
refresh_token = ARGV[0]
puts refresh_token

client_id = ENV['FITBIT_CLIENT_ID']
client_secret = ENV['FITBIT_CLIENT_SECRET']

client = OAuth2::Client.new(client_id, client_secret,
                            site: 'https://api.fitbit.com',
                            authorize_url: 'https://www.fitbit.com/oauth2/authorize',
                            token_url: 'https://api.fitbit.com/oauth2/token')

bearer_token = "#{client_id}:#{client_secret}"
encoded_bearer_token = Base64.strict_encode64(bearer_token)

# get access_token from refresh_token
auth_token = OAuth2::AccessToken.new(
  client,
  refresh_token,
  refresh_token: refresh_token,
  expires_at: 3600,
  scope: 'heartrate'
)

access_token = auth_token.refresh!(headers: { 'Authorization' => "Basic #{encoded_bearer_token}" })
hash = access_token.to_hash
puts hash

# create access_token instance
token = OAuth2::AccessToken.new(
  client,
  hash[:access_token],
  refresh_token: refresh_token,
  expires_at: 3600,
  scope: 'heartrate'
)

now = Time.now
today = now.strftime('%Y-%m-%d')

endpoint = "https://api.fitbit.com/1/user/-/activities/heart/date/#{today}/1d/1sec.json"
# endpoint = 'https://api.fitbit.com/1/user/-/activities/heart/date/today/1d/1min/time/00:00/12:00.json'
response = token.get(endpoint)

puts response.inspect
puts response.body
