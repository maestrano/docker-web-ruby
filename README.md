# Maestrano web-ruby
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

## Process configuration
Maestrano web-ruby uses your Procfile to run processes. See [the foreman site](http://blog.daviddollar.org/2011/05/06/introducing-foreman.html) for more information on procfiles.

Example:
```yaml
web: bundle exec puma -t 5:5 -p ${PORT:-3000}
worker: bundle exec rake jobs:work
```

## Logging
For Rails 4 you may want to add the `rails_12factor` gem to your Gemfile under the `production` group to redirect output to STDOUT. For Rails 5 you can add STDOUT logging directly your production.rb file.

See https://github.com/heroku/rails_12factor for more information.

## Nginx configuration
You can customise the default nginx configuration for your app to accomodate any kind of requirements for serving your static assets and SPAs.
Just drop a `nginx.conf` file in the root of your folder and it will automatically be picked up by web-ruby.

The default nginx configuration file is [available here](2.3/app.conf).

## Deploy hook
If you need to perform specific configuration activities at deploy time - such as fetching a file from a remote S3 repository - you can specify a deploy hook at the root of your project called ".deploy-hook". This file must be a shell script. Any environment variable passed to the container will be available to the deploy-hook script. The deploy-hook script is run after the project has been checked out and before bundler is run.

**Example:** PROJECT_ROOT/.deploy-hook
```sh
#!/bin/bash
#
# Example of deploy hook
#
echo "This is a deploy hook!"
echo "I run after checkout..."
echo "...and before bundler"
```
