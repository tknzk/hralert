require 'oauth2'

client_id = ENV['FITBIT_CLIENT_ID']
client_secret = ENV['FITBIT_CLIENT_SECRET']

redirect_uri = 'http://localhost:3002/callback'

client = OAuth2::Client.new(client_id, client_secret, site: 'https://api.fitbit.com', authorize_url: 'https://www.fitbit.com/oauth2/authorize', token_url: 'https://api.fitbit.com/oauth2/token')

# generate authorized_url
puts client.auth_code.authorize_url(redirect_uri: redirect_uri, scope: 'heartrate')

