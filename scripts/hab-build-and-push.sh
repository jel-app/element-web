#!/bin/bash

export TARGET_S3_BUCKET=$1
export BUILD_NUMBER=$2
export GIT_COMMIT=$3
export BUILD_VERSION="${BUILD_NUMBER} (${GIT_COMMIT})"
export HAB_BLDR_URL="https://bldr.biome.sh"

# Build the package, upload it, and start the service so we deploy to staging target.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/../habitat/plan.sh"
PKG="$pkg_origin/$pkg_name"

pushd "$DIR/.."

trap "rm /hab/svc/$pkg_name/var/deploying && sudo /usr/bin/hab-clean-perms && chmod -R a+rw ." EXIT

# Wait for a lock file so we serialize deploys
mkdir -p /hab/svc/$pkg_name/var
while [ -f /hab/svc/$pkg_name/var/deploying ]; do sleep 1; done
touch /hab/svc/$pkg_name/var/deploying

rm -rf results
mkdir -p results
cp -R ~/.ssh ./dotssh # Copy github.com credentials becuase of shared-aframe private repo dep
cp -R ~/.aws ./dotaws # Copy AWS credentials
sudo /usr/bin/hab-docker-studio run build
hab svc unload $PKG
sudo /usr/bin/hab-pkg-install results/*.hart
hab svc load $PKG
hab svc stop $PKG

# Apparently these vars come in from jenkins with quotes already
cat > build-config.toml << EOTOML
[general]

[deploy]
type = "s3"
target = $TARGET_S3_BUCKET
region = "us-west-1"
EOTOML

cat build-config.toml
sudo /usr/bin/hab-user-toml-install $pkg_name build-config.toml
hab svc start $PKG
#sudo /usr/bin/hab-pkg-upload results/*.hart
