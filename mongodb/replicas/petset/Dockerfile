FROM mongo:3.5.6

RUN mkdir /secret
RUN chmod 700 /secret
COPY mongodb-keyfile /secret/
RUN chmod 600 /secret/mongodb-keyfile