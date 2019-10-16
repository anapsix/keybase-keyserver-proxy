FROM ruby:alpine
LABEL maintainer="Anastas Dancha <https://github.com/anapsix>"
ENV APP_ROOT=/app
WORKDIR ${APP_ROOT}
COPY Gemfile Gemfile.lock ${APP_ROOT}/
RUN apk add --no-cache libstdc++ g++ make &&\
    bundle install --deployment &&\
    apk del libstdc++ g++ make
COPY . ${APP_ROOT}/
EXPOSE 11371
CMD /app/start.sh
