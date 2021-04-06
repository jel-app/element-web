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
    core/coreutils # Grep is used in runhook
)

do_build() {
  ln -fs "$(hab pkg path core/coreutils)/bin/env" /usr/bin/env

  [ -d "./dotssh" ] && rm -rf ~/.ssh && mv dotssh ~/.ssh
  [ -d "./dotaws" ] && rm -rf ~/.aws && mv dotaws ~/.aws

  export BASE_ASSETS_PATH="https://assets.jel.app/neon/assets/"
  export BUILD_VERSION="${pkg_version}.$(echo $pkg_prefix | cut -d '/' -f 7)"

  npm_config_cache=.npm npm ci --verbose --no-progress
  npm_config_cache=.npm yarn build
  
  mkdir -p dist/pages
  mkdir -p dist/assets
  mv webapp/*.html dist/pages
  mv webapp/indexeddb-worker.js dist/pages
  cp -R webapp/* dist/assets
  cp config*.json dist/assets
  rm -rf webapp

  # HACK paths within CSS are wrong, gave up on trying to do this more nicely somewhere else
  find dist/assets/bundles -type f -name *.css -exec sed -i "s/assets\.jel\.app\//assets.jel.app\/neon\/assets\//g" {} \;
}

do_install() {
  cp -R dist "${pkg_prefix}"
}
