#!/bin/bash -x
source '/usr/local/lib/rvm'
echo `pwd`
bundle install --no-frozen --path "/home/jenkins/bundles/${JOB_NAME}"
bundle exec rake spec