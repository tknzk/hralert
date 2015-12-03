# hralert

# setup
## fitbit application
- register fitbit application
  - https://dev.fitbit.com/
  - require application type: Personal

# sample code
## get access_token and refresh_token

- create ahrorized_url
```
bundle exec ruby 01a.rb
```

- get authorized_code on browser
- get access_token/refresh_token

```
bundle exec ruby 02b.rb AUTHORIZED_CODE
```

- get heartrate.json use refresh_token

```
bundle exec ruby 03c.rb REFRESH_TOKEN
```

