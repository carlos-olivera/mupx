#!/bin/bash

APPNAME=<%= appName %>
APP_PATH=/opt/$APPNAME
BUNDLE_PATH=$APP_PATH/current
ENV_FILE=$APP_PATH/config/env.list
PORT=<%= port %>
USE_LOCAL_MONGO=<%= useLocalMongo? "1" : "0" %>

# Remove previous version of the app, if exists
docker rm -f $APPNAME

# Remove frontend container if exists
docker rm -f $APPNAME-frontend

# We don't need to fail the deployment because of a docker hub downtime
set +e
docker pull carlosolivera/reactionmovilgate:v1
set -e

if [ "$USE_LOCAL_MONGO" == "1" ]; then
  docker run \
    -d \
    --restart=always \
    --publish=$PORT:80 \
    --volume=$BUNDLE_PATH:/bundle \
    --env-file=$ENV_FILE \
    --link=mongodb:mongodb \
    --hostname="$HOSTNAME-$APPNAME" \
    --env=MONGO_URL=mongodb://mongodb:27017/$APPNAME \
    --name=$APPNAME \
    <% for (var hosts = Object.keys(customHosts || {}), i = 0, l = hosts.length; i < l; i ++) { %>--add-host=<%= hosts[i] %>:<%= customHosts[hosts[i]] %><%= (i < l - 1 ? " \\\n    " : "") %><% } %> \
    carlosolivera/reactionmovilgate:v1
else
  docker run \
    -d \
    --restart=always \
    --publish=$PORT:80 \
    --volume=$BUNDLE_PATH:/bundle \
    --hostname="$HOSTNAME-$APPNAME" \
    --env-file=$ENV_FILE \
    --name=$APPNAME \
    <% for (var hosts = Object.keys(customHosts || {}), i = 0, l = hosts.length; i < l; i ++) { %>--add-host=<%= hosts[i] %>:<%= customHosts[hosts[i]] %><%= (i < l - 1 ? " \\\n    " : "") %><% } %> \
    carlosolivera/reactionmovilgate:v1
fi

<% if(typeof sslConfig === "object")  { %>
  # We don't need to fail the deployment because of a docker hub downtime
  set +e
  docker pull carlosolivera/mup-frontend-server:latest
  set -e
  docker run \
    -d \
    --restart=always \
    --volume=/opt/$APPNAME/config/bundle.crt:/bundle.crt \
    --volume=/opt/$APPNAME/config/private.key:/private.key \
    --link=$APPNAME:backend \
    --publish=<%= sslConfig.port %>:443 \
    --publish=80:80 \
    --name=$APPNAME-frontend \
    carlosolivera/mup-frontend-server /start.sh
<% } %>
