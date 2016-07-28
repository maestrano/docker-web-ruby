#!/bin/bash
set -e

# Go to app directory
cd /app

# Clone app from git
if [ -n "$GIT_URL" ] && [ -n "$GIT_BRANCH" ]; then
  [ -d /app/.git ] || git clone --branch "$GIT_BRANCH" --depth 50 $GIT_URL /app
  [ -n "$GIT_COMMIT_ID" ] && git checkout -qf $GIT_COMMIT_ID

  # Install all required gems
  [ "$NO_BUNDLE" == "true" ] || bundle install --without development test

  # Migrate database
  [ "$NO_MIGRATE" == "true" ] || bundle exec rake db:migrate

  # Pre-compile assets
  [ "$NO_COMPILE" == "true" ] || bundle exec rake assets:precompile
fi

# Perform command - default is "foreman start" (see Dockerfile)
exec "$@"
