FROM ruby:2.6-alpine3.11

ENV BUILD_PACKAGES curl-dev build-base

RUN apk update && \
    apk upgrade && \
    apk add git curl $BUILD_PACKAGES

WORKDIR /usr/src/app

COPY . .

RUN gem install bundler:1.17.3 && \
    bundle install && \
    rake install:local

CMD ["sh"]
