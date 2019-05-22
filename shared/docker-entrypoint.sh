#!/bin/bash
set -e

# Go to app directory
cd /app

# Set default environment variables
export FOREMAN_OPTS=${FOREMAN_OPTS:-""}
export RACK_ENV=${RACK_ENV:-production}
export RAILS_ENV=${RAILS_ENV:-production}
export RAILS_LOG_TO_STDOUT=${RAILS_LOG_TO_STDOUT:-true}
export GIT_BRANCH=${GIT_BRANCH:-master}
export BUNDLE_JOBS=${BUNDLE_JOBS:-$(nproc)} # default to number of cores
export S3_REGION=${S3_REGION:-ap-southeast-1}

# Configure bundler to use gemstash server if specified
if [ -n "$GEMSTASH_SERVER" ]; then
  bundle config mirror.https://rubygems.org $GEMSTASH_SERVER
  bundle config mirror.https://rubygems.org.fallback_timeout 3
fi

# Clone app from git
if [ -n "$GIT_URL" ] && [ -n "$GIT_BRANCH" ]; then
  echo "Retrieving code for branch: $GIT_BRANCH"
  [ -d /app/.git ] || git clone --branch "$GIT_BRANCH" --depth 50 $GIT_URL /app
  [ -n "$GIT_COMMIT_ID" ] && git checkout -qf $GIT_COMMIT_ID
  echo $(git log -1 HEAD --pretty)
# Download app from S3
elif [ -n "$S3_URI" ]; then
  if [ -z "$S3_SECRET_ACCESS_KEY" ]; then
    opts="--no-sign-request"
  fi
  # Setting Signature Version 4 for S3 Request Authentication
  aws configure set s3.signature_version s3v4
  AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY AWS_DEFAULT_REGION=$S3_REGION aws s3 cp $opts $S3_URI ./
  archive_file=${S3_URI##*/}
  echo "Unzipping $archive_file"
  tar xf $archive_file
  rm -f $archive_file
fi

# Run deploy hook
if [ -f /app/.deploy-hook ]; then
  [ "$NO_HOOK" == "true" ] || bash /app/.deploy-hook
fi

# Run bundler
if [ -f /app/Gemfile ]; then
  # Install all required gems
  # Number of bundle jobs is defined by BUNDLE_JOBS and defaults to the number
  # of available cores
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
