FROM ruby
MAINTAINER Gaelan D'costa <gdcosta@gmail.com>?

RUN mkdir -p /srv/app

ADD . /srv/app
WORKDIR /srv/app
RUN ["bundle", "install"]

CMD ["bundle", "exec", "ebooks", "start"]
