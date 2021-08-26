FROM ruby:2.6-alpine3.13
LABEL maintainer="Anastas Dancha <https://github.com/anapsix>"
ENV APP_ROOT=/app
WORKDIR ${APP_ROOT}
COPY Gemfile Gemfile.lock ${APP_ROOT}/
RUN apk upgrade -U &&\
    apk add --no-cache g++ make &&\
    bundle install --deployment &&\
    apk del g++ make &&\
    rm -rf /var/cache/apk
COPY . ${APP_ROOT}/
EXPOSE 11371
CMD /app/start.sh
