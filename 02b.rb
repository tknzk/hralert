# frozen_string_literal: true

require 'oauth2'
require 'base64'
code = ARGV[0]
puts code

client_id = ENV['FITBIT_CLIENT_ID']
client_secret = ENV['FITBIT_CLIENT_SECRET']

redirect_uri = 'http://localhost:3002/callback'

client = OAuth2::Client.new(client_id, client_secret,
                            site: 'https://api.fitbit.com',
                            authorize_url: 'https://www.fitbit.com/oauth2/authorize',
                            token_url: 'https://api.fitbit.com/oauth2/token')

bearer_token = "#{client_id}:#{client_secret}"
encoded_bearer_token = Base64.strict_encode64(bearer_token)

access_token = client.auth_code.get_token(
  code,
  grant_type: 'authorization_code',
  client_id: client_id,
  redirect_uri: redirect_uri,
  headers: { 'Authorization' => "Basic #{encoded_bearer_token}" }
)

hash = access_token.to_hash
puts hash

puts '=x======'
p access_token.get('https://api.fitbit.com/1/user/-/activities/heart/date/today/1d.json')
puts '=x======'
