FROM docker.elastic.co/elasticsearch/elasticsearch:5.6.3
MAINTAINER Slawek Kolodziej <hfrntt@gmail.com>
RUN elasticsearch-plugin install analysis-stempel
RUN yes | elasticsearch-plugin install https://github.com/vvanholl/elasticsearch-consul-discovery/releases/download/5.6.3.0/elasticsearch-consul-discovery-5.6.3.0.zip
ENV ES_JAVA_OPTS -Xms512m -Xmx512m

RUN mkdir -p /usr/share/elasticsearch/data && chown elasticsearch:elasticsearch /usr/share/elasticsearch/data
VOLUME /usr/share/elasticsearch/data

COPY elasticsearch-service.json /usr/share/elasticsearch/elasticsearch-service.json
COPY elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9200
CMD [ "elasticsearch" ]