pkg_name=neon
pkg_origin=jel
pkg_maintainer="Greg Fodor <gfodor@jel.app>"

pkg_version="1.0.0"
pkg_license=('None')
pkg_description="Element fork for jel"
pkg_upstream_url="https://jel.app/"
pkg_build_deps=(
    core/coreutils
    core/bash
    core/node10/10.16.2 # Latest node10 fails during npm ci due to a permissions error creating tmp dir
    core/git
    core/yarn
)

pkg_deps=(
    core/aws-cli # AWS cli used for run hook when uploading to S3
)

do_build() {
  ln -fs "$(hab pkg path core/coreutils)/bin/env" /usr/bin/env

  [ -d "./dotssh" ] && rm -rf ~/.ssh && mv dotssh ~/.ssh
  [ -d "./dotaws" ] && rm -rf ~/.aws && mv dotaws ~/.aws

  # main client
  npm_config_cache=.npm npm ci --verbose --no-progress
  npm_config_cache=.npm yarn build
}

do_install() {
  cp -R webapp "${pkg_prefix}"
  cp version "${pkg_prefix}"
}
