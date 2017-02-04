# Maestrano web-ruby
Docker image packed with ruby, git and nginx.

[![Build Status](https://travis-ci.org/maestrano/docker-web-ruby.svg?branch=master)](https://travis-ci.org/maestrano/docker-web-ruby)


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

The foreman configuration can be overriden at runtime by setting the `FOREMAN_OPTS` environment variable. Considering the Procfile above running the following command would only run the "web" proc.

```
docker run -P -d -e FOREMAN_OPTS="-m web=1" -e GIT_URL=https://github.com/alachaum/sample_app_rails_4 maestrano/web-ruby
```

## Logging
For Rails 4 you may want to add the `rails_12factor` gem to your Gemfile under the `production` group to redirect output to STDOUT. For Rails 5 you can add STDOUT logging directly your production.rb file.

See https://github.com/heroku/rails_12factor for more information.

## Gem caching using Gemstash
If you have a [gemstash server](https://github.com/bundler/gemstash) running you can pass its URL to the container via the `GEMSTASH_SERVER` environment variable to speed up the entrypoint.

Example:
```
docker run -P -d -e GEMSTASH_SERVER="http://someserver:9292" -e GIT_URL=https://github.com/alachaum/sample_app_rails_4 maestrano/web-ruby
```

## Nginx configuration
You can customise the default nginx configuration for your app to accomodate any kind of requirements for serving your static assets and SPAs.
Just drop a `nginx.conf` file in the root of your folder and it will automatically be picked up by web-ruby.

The default nginx configuration file is [available here](2.3/app.conf).

## Deploy hooks

### .deploy-hook
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

### .post-deploy-hook
The post-deploy-hook behavior is similar to the deploy-hook, but it is run after the deployment and just before last command is performed (eg. "foreman start").

## Docker Healthcheck
The image provides a **default Docker healthcheck** which curls your app on the root path. You can customize this healthcheck by adding a `.healthcheck` in the root directory of your application. This healtcheck file should be a bash script returning a non-zero exit code on failure. The healthcheck can be completely disabled by adding "NO_HEALTHCHECK=true" to the list of container environment variables.

**Example:** PROJECT_ROOT/.healtcheck
```sh
#!/bin/bash
#
# Example of custom healthcheck
#
curl http://localhost/ping && \
curl http://localhost/version
```
