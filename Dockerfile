FROM alpine:3.4
MAINTAINER Gaelan D'costa <gdcosta@gmail.com>

# Install base packages
# RUN apk update
# RUN apk upgrade

# Install deps & clean cache
RUN apk add --update ruby ruby-dev ruby-bundler build-base && \
    rm -rf /var/cache/apk/*

# Setup App
RUN ["mkdir", "-p", "/srv/app"]
WORKDIR /srv/app

COPY Gemfile Gemfile.lock /srv/app/
RUN ["bundle", "install"]
COPY bots.rb /srv/app/
COPY model /srv/app/model

# Run app
CMD ["bundle", "exec", "ebooks", "start"]
