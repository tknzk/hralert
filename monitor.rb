# frozen_string_literal: true

require 'oauth2'
require 'base64'
require 'redis'
require 'json'
require 'slack-notifier'
require 'rest-client'

client_id = ENV['FITBIT_CLIENT_ID']
client_secret = ENV['FITBIT_CLIENT_SECRET']

if !ENV['REDIS_URL'].nil?
  uri   = URI.parse ENV['REDIS_URL']
  redis = Redis.new host: uri.host, port: uri.port, password: uri.password
else
  redis = Redis.new host: '127.0.0.1', port: '6379'
end

refresh_token = redis.get 'refresh_token'

refresh_token = ARGV[0] if refresh_token.nil?

refresh_token = ARGV[0] if ARGV[1] == 'overwrite'

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

# save refresh_token
redis.set 'refresh_token', hash[:refresh_token]

# create access_token instance
token = OAuth2::AccessToken.new(
  client,
  hash[:access_token],
  refresh_token: refresh_token,
  expires_at: 3600,
  scope: 'heartrate'
)

now = Time.now
term = 1800
start = (now - term).strftime('%H:%M')
finish = now.strftime('%H:%M')

endpoint = "https://api.fitbit.com/1/user/-/activities/heart/date/today/1d/1min/time/#{start}/#{finish}.json"
puts endpoint
response = token.get(endpoint)

result = JSON.parse(response.body)

activities_heart_intraday = result['activities-heart-intraday']
datas = []
mackerel = {}
activities_heart_intraday['dataset'].each do |data|
  datas << "#{data['time']} => #{data['value']}"
  epoch = Time.parse("#{now.strftime('%Y-%m-%d')} #{data['time']}").to_i
  mackerel = [{
    name:  'heartbeat',
    time:  epoch,
    value: data['value']
  }]
  begin
    RestClient.post('https://mackerel.io/api/v0/services/heartrate/tsdb',
                    mackerel.to_json,
                    'Content-Type' => 'application/json',
                    'X-Api-Key' => ENV['MACKEREL_API_KEY'])
  rescue StandardError => e
    puts e.message
  end
end

if datas.empty?
  subject = "HeartRate Log checked: #{now}\n NOT GET HEART RATE DATA"

  slack = Slack::Notifier.new(ENV['HRALERT_NG_SLACK_WEBHOOK_URL'], channel: ENV['HRALERT_SLACK_WEBHOOK_CHANNEL'])
  slack.ping subject

else
  subject = "HeartRate Log checked: #{now}"
  note = {
    text: datas.join("\n"),
    color: 'good'
  }

  slack = Slack::Notifier.new(ENV['HRALERT_OK_SLACK_WEBHOOK_URL'], channel: ENV['HRALERT_SLACK_WEBHOOK_CHANNEL'])
  slack.ping subject, attachments: [note]

end
