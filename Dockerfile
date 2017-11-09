FROM ruby:2.4

ARG private_gem_oauth_token

USER root

RUN apt-get update

RUN apt-get install -y libgtk-3-0 libdbusmenu-glib-dev libx11-xcb-dev xvfb postgresql postgresql-contrib emacs curl

# firefox and geckodriver
RUN wget 'https://ftp.mozilla.org/pub/firefox/releases/56.0/linux-x86_64/en-US/firefox-56.0.tar.bz2' \ 
  && tar -xjf firefox-56.0.tar.bz2 \ 
  && mv firefox /opt/firefox56 \ 
  && ln -s /opt/firefox56/firefox /usr/bin/firefox 

RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.18.0/geckodriver-v0.18.0-linux64.tar.gz \
  && tar -zxvf geckodriver-v0.18.0-linux64.tar.gz \ 
  && mv geckodriver /usr/bin/

ENV DISPLAY :10

ENV PRIVATE_GEM_OAUTH_TOKEN $private_gem_oauth_token

WORKDIR /tmp/gems
ADD Gemfile /tmp/gems/Gemfile
ADD Gemfile.lock /tmp/gems/Gemfile.lock
RUN bundle install 

ADD . /app

WORKDIR /app 