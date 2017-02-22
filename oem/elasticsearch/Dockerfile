FROM elasticsearch:5.2.0

RUN bin/elasticsearch-plugin install x-pack --batch
RUN bin/elasticsearch-plugin install analysis-kuromoji --batch
RUN bin/elasticsearch-plugin install ingest-attachment --batch

# COPY elasticsearch.yml  /usr/share/elasticsearch/config/elasticsearch.yml