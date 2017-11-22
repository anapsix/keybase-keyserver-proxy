FROM debian:stable-slim
MAINTAINER Anastas Dancha <anapsix@random.io>
COPY . /srv/app
WORKDIR /srv/app
RUN apt-get update && apt-get dist-upgrade --yes && \
    apt-get install ruby ruby-dev build-essential --yes && \
    gem install bundle --no-doc && \
    bundle install --deployment && \
    apt-get purge build-essential ruby-dev --yes && \
    apt-get autoremove --yes && \
    apt-get clean all && \
    rm -rf /var/cache/*
    
EXPOSE 11317
CMD /srv/app/start.sh