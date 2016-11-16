#!/bin/bash
set -e

# Go to app directory
cd /app

# Set default environment variables
export RACK_ENV=${RACK_ENV:-production}
export RAILS_ENV=${RAILS_ENV:-production}
export RAILS_LOG_TO_STDOUT=${RAILS_LOG_TO_STDOUT:-true}
export GIT_BRANCH=${GIT_BRANCH:-master}

# Clone app from git
if [ -n "$GIT_URL" ] && [ -n "$GIT_BRANCH" ]; then
  [ -d /app/.git ] || git clone --branch "$GIT_BRANCH" --depth 50 $GIT_URL /app
  [ -n "$GIT_COMMIT_ID" ] && git checkout -qf $GIT_COMMIT_ID
fi

# Run deploy hook
if [ -f /app/.deploy-hook ]; then
  [ "$NO_HOOK" == "true" ] || bash /app/.deploy-hook
fi

# Run bundler
if [ -f /app/Gemfile ]; then
  # Install all required gems
  [ "$NO_BUNDLE" == "true" ] || bundle install --without development test
fi

# Run rails specific tasks
if [ -f /app/config/application.rb ]; then
  # Load schema (you should unset this var afterwards)
  [ "$RAILS_LOAD_SCHEMA" == "true" ] && bundle exec rake db:schema:load

  # Migrate database
  [ "$NO_MIGRATE" == "true" ] || bundle exec rake db:migrate

  # Pre-compile assets
  [ "$NO_COMPILE" == "true" ] || bundle exec rake assets:precompile
fi

# Nginx configuration
if [ ! "$NO_NGINX" == "true" ] && [ -f /app/nginx.conf ]; then
  rm -f /etc/nginx/sites-enabled/*
  cp -p /app/nginx.conf /etc/nginx/sites-enabled/
fi

# Update ownership
chown -R www-data:www-data /app /var/log/app

# Run post-deploy hook
if [ -f /app/.post-deploy-hook ]; then
  [ "$NO_HOOK" == "true" ] || bash /app/.post-deploy-hook
fi

# Perform command - default is "foreman start" (see Dockerfile)
exec "$@"
