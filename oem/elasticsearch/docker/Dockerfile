FROM elasticsearch:5.2.1-alpine

RUN bin/elasticsearch-plugin install analysis-kuromoji --batch
RUN bin/elasticsearch-plugin install ingest-attachment --batch
RUN bin/elasticsearch-plugin install org.codelibs:elasticsearch-analysis-kuromoji-neologd:5.2.1 --batch

COPY userdict_ja.txt  /usr/share/elasticsearch/config/userdict_ja.txt
COPY synonym.txt  /usr/share/elasticsearch/config/synonym.txt
COPY globalsearch_template.json  /usr/share/elasticsearch/config/globalsearch_template.json

