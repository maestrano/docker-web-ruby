# docker-ruby
Docker image packed with ruby, git and nginx.

## Examples
Launch a rails app from a public github repository
```
docker run -P -d -e GIT_URL=https://github.com/alachaum/sample_app_rails_4 -e GIT_BRANCH=master maestrano/web-ruby
```

Launch a rails app from a private github repository
```
docker run -P -d -e GIT_URL=https://MY_GITHUB_OAUTH_TOKEN@github.com/alachaum/sample_app_rails_4 -e GIT_BRANCH=master maestrano/web-ruby
```

Launch a rails app from a local folder
```
docker run -P -d -v /some/local/app:/app maestrano/web-ruby
```

## Logging
For Rails 4 you may want to add the `rails_12factor` gem to your Gemfile under the `production` group to redirect output to STDOUT. For Rails 5 you can add STDOUT logging directly your production.rb file.

See https://github.com/heroku/rails_12factor for more information.
