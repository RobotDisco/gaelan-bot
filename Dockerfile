FROM alpine:3.3
MAINTAINER Gaelan D'costa <gdcosta@gmail.com>

# Install base packages
# RUN apk update
# RUN apk upgrade

# Install deps & clean cache
RUN apk add build-base --update ca-certificates ruby ruby-dev ruby-io-console ruby-bundler && \
    rm -rf /var/cache/apk/*

# Setup App
RUN ["mkdir", "-p", "/srv/app"]

COPY Gemfile Gemfile.lock bots.rb /srv/app/

WORKDIR /srv/app
RUN ["bundle", "install"]

COPY config.rb /srv/app/
COPY model /srv/app/model/

# Run app
CMD ["bundle", "exec", "ebooks", "start"]
