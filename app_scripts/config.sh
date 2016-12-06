#!/bin/sh

# personal directory
DIR_NAME=${DIR_NAME:-jeanepaul}

# builder machine IP
BUILDER_IP=${BUILDER_IP:-10.0.1.21}
# ssh username for builder machine
SSH_USER=${SSH_USER:-b-eee}

# go container version to use for building
GOVERSION=${GOVERSION:-1.7.1-alpine}
# go build OS target
OS=${OS:-darwin}
# go build architecture
ARCH=${ARCH:-amd64}
