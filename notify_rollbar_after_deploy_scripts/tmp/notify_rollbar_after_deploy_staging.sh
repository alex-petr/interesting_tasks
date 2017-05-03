#!/usr/bin/env bash

ACCESS_TOKEN=7580499de3e2a2e84a1c742002c01eab
ENVIRONMENT=staging
REVISION=`git log -n 1 --pretty=format:"%H"`
LOCAL_USERNAME=`whoami`
ROLLBAR_USERNAME=alex_petrov
COMMENT="Elastic Beanstalk Staging: `git log -n 1 --pretty=format:"%s"`"

curl https://api.rollbar.com/api/1/deploy/ \
  -F access_token=$ACCESS_TOKEN \
  -F environment=$ENVIRONMENT \
  -F revision=$REVISION \
  -F local_username=$LOCAL_USERNAME \
  -F rollbar_username=$ROLLBAR_USERNAME \
  -F comment="$COMMENT"
