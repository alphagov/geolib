#!/bin/bash -x
source '/usr/local/lib/rvm'
rm -f Gemfile.lock
bundle install --no-frozen --path "/home/jenkins/bundles/${JOB_NAME}"
bundle exec rake spec