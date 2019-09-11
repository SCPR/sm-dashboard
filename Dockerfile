FROM phusion/passenger-ruby24
MAINTAINER SCPR Developers <scprdev@scpr.org>

RUN apt-get update

RUN apt-get install -y \
  make \
  gcc \
  libgcc-4.8-dev \
  g++ \
  libc-dev \
  libffi-dev \
  git \
  libmysqlclient-dev \
  ruby-json \
  libyaml-dev \
  zlib1g \
  libxml2-dev \
  libxslt-dev \
  tzdata \
  openssl \
  libcurl4-openssl-dev

RUN apt-get install -y ruby`ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]'`-dev

RUN groupadd scpr && useradd -g scpr scpr

ENV HOME /streamdash
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT true

RUN mkdir $HOME
WORKDIR $HOME

RUN gem install bundler -v '1.17.1'

ENV PATH="${HOME}/bin:${PATH}"

COPY Gemfile* $HOME/
RUN bundle install --without development test --binstubs

COPY . $HOME
RUN bundle exec rake assets:precompile
RUN rm config/secrets.yml


