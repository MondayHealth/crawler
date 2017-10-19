FROM ruby:2.4

ARG private_gem_oauth_token

USER root

RUN apt-get update

RUN apt-get install -y libgtk-3-0 libdbusmenu-glib-dev libx11-xcb-dev xvfb postgresql postgresql-contrib

# firefox and geckodriver
RUN wget 'https://ftp.mozilla.org/pub/firefox/releases/55.0/linux-x86_64/en-US/firefox-55.0.tar.bz2' \ 
  && tar -xjf firefox-55.0.tar.bz2 \ 
  && mv firefox /opt/firefox55 \ 
  && ln -s /opt/firefox55/firefox /usr/bin/firefox 

RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.11.1/geckodriver-v0.11.1-linux64.tar.gz \
  && tar -zxvf geckodriver-v0.11.1-linux64.tar.gz \ 
  && mv geckodriver /usr/bin/

ENV DISPLAY :10

WORKDIR /app
COPY . ./

ENV PRIVATE_GEM_OAUTH_TOKEN $private_gem_oauth_token
ENV BUNDLE_PATH="/app/storage/vendor/bundle"
ENV BUNDLE_BIN="/app/storage/vendor/bundle/bin"
ENV PATH="/app/storage/vendor/bundle/bin:$PATH"

RUN PRIVATE_GEM_OAUTH_TOKEN=$PRIVATE_GEM_OAUTH_TOKEN bundle install 