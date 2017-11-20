FROM elasticsearch:5.6.3-alpine
MAINTAINER Slawek Kolodziej <hfrntt@gmail.com>
RUN apk add --no-cache 'su-exec>=0.2' curl


RUN elasticsearch-plugin install analysis-stempel
RUN yes | elasticsearch-plugin install https://github.com/vvanholl/elasticsearch-consul-discovery/releases/download/5.6.3.0/elasticsearch-consul-discovery-5.6.3.0.zip
ENV ES_JAVA_OPTS -Xms512m -Xmx512m

HEALTHCHECK --timeout=5s CMD curl --silent -O http://$HOSTNAME:9200/_cat/health

RUN mkdir -p /usr/share/elasticsearch/data && chown elasticsearch:elasticsearch /usr/share/elasticsearch/data

COPY elasticsearch-service.json /usr/share/elasticsearch/elasticsearch-service.json
COPY elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml
COPY docker-entrypoint.sh /usr/local/bin/

EXPOSE 9200 9300

ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "elasticsearch" ]