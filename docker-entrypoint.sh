#!/bin/sh
set -e

# Assume that the HTTP client is running on Docker bridge on default port
if [ "${ELASTICSEARCH_CONSUL_ADDR}" = 'host' ]; then
  export ELASTICSEARCH_CONSUL_ADDR=`ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1`:8500
elif [ -z ${ELASTICSEARCH_CONSUL_ADDR+x} ]; then
  export ELASTICSEARCH_CONSUL_ADDR=`ip ro | grep default | awk '{print $3}'`:8500
fi

# If hostname is not provided, use EC2 instance hostname
if [ -z ${ELASTICSEARCH_NODE_NAME+x} ]; then
  export ELASTICSEARCH_NODE_NAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname | sed -E 's/(ip(-[0-9]{1,3}){4})\..+/\1/')
fi

# If addres is not provided, use EC2 instance IP
if [ -z ${ELASTICSEARCH_NODE_ADDR+x} ]; then
  export ELASTICSEARCH_NODE_ADDR=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
fi

# If addres is not provided, use EC2 instance IP
if [ -z ${ELASTICSEARCH_SERVICE_ADDR+x} ]; then
  export ELASTICSEARCH_SERVICE_ADDR=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
fi

# Generate service name if it's not defined
if [ -z ${ELASTICSEARCH_SERVICE_NAME+x} ]; then
  export ELASTICSEARCH_SERVICE_NAME="elasticsearch"
fi

# Generate service id if it's not defined
if [ -z ${ELASTICSEARCH_SERVICE_ID+x} ]; then
  export ELASTICSEARCH_SERVICE_ID="$ELASTICSEARCH_SERVICE_NAME-$HOSTNAME"
fi

# Put values in the service config file
sed -i "s/ELASTICSEARCH_NODE_NAME/${ELASTICSEARCH_NODE_NAME}/g" "/usr/share/elasticsearch/elasticsearch-service.json"
sed -i "s/ELASTICSEARCH_NODE_ADDR/${ELASTICSEARCH_NODE_ADDR}/g" "/usr/share/elasticsearch/elasticsearch-service.json"
sed -i "s/ELASTICSEARCH_SERVICE_ADDR/${ELASTICSEARCH_SERVICE_ADDR}/g" "/usr/share/elasticsearch/elasticsearch-service.json"
sed -i "s/ELASTICSEARCH_SERVICE_NAME/${ELASTICSEARCH_SERVICE_NAME}/g" "/usr/share/elasticsearch/elasticsearch-service.json"
sed -i "s/ELASTICSEARCH_SERVICE_ID/${ELASTICSEARCH_SERVICE_ID}/g" "/usr/share/elasticsearch/elasticsearch-service.json"
sed -i "s/ELASTICSEARCH_USER/${ELASTICSEARCH_USER}/g" "/usr/share/elasticsearch/elasticsearch-service.json"
sed -i "s/ELASTICSEARCH_PASS/${ELASTICSEARCH_PASS}/g" "/usr/share/elasticsearch/elasticsearch-service.json"

sed -i "s/ELASTICSEARCH_SERVICE_ADDR/${ELASTICSEARCH_SERVICE_ADDR}/g" "/usr/share/elasticsearch/config/elasticsearch.yml"
sed -i "s/ELASTICSEARCH_SERVICE_NAME/${ELASTICSEARCH_SERVICE_NAME}/g" "/usr/share/elasticsearch/config/elasticsearch.yml"

SERVICE_CONFIG=$(cat /usr/share/elasticsearch/elasticsearch-service.json)
CONSUL_RESP=$(curl -X PUT -d "$SERVICE_CONFIG" "http://$ELASTICSEARCH_CONSUL_ADDR/v1/agent/service/register")

if [ "$CONSUL_RESP" == "" ]; then
  echo "Service registered"
else
  echo "Consul response: $CONSUL_RESP"
  exit 1
fi


# Add elasticsearch as command if needed
if [ "${1:0:1}" = '-' ]; then
  set -- elasticsearch "$@"
fi

# Drop root privileges if we are running elasticsearch
# allow the container to be started with `--user`
if [ "$1" = 'elasticsearch' -a "$(id -u)" = '0' ]; then
  # Change the ownership of user-mutable directories to elasticsearch
  for path in \
    /usr/share/elasticsearch/data \
    /usr/share/elasticsearch/logs \
  ; do
    chown -R elasticsearch:elasticsearch "$path"
  done

  set -- su-exec elasticsearch "$@"
  #exec su-exec elasticsearch "$BASH_SOURCE" "$@"
fi

# As argument is not related to elasticsearch,
# then assume that user wants to run his own process,
# for example a `bash` shell to explore this image
exec "$@"