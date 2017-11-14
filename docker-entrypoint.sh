#!/bin/sh
set -e

# Put values in the service config file
sed -i "s/CONSUL_SERVICE_NAME/${ELASTICSEARCH_SERVICE_NAME}/g" "/usr/share/elasticsearch/config/elasticsearch.yml"

exec "$@"