#!/bin/bash -x
source '/usr/local/lib/rvm'
export GEM_HOME="/home/jenkins/bundles/${JOB_NAME}"
bundle install && bundle exec rake spec