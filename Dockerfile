FROM perl:5.22.2

LABEL authors="James Biard, Andrew Buddenberg, Kathryn Tipton"
LABEL version="1.0.1"

ENV PERL5LIB /usr/share/perl5
ENV DEBIAN_FRONTEND noninteractive

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' > /etc/apt/sources.list.d/pgdg.list

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50

RUN apt-get update \
    && apt-get install -y \
           debian-keyring \
           debian-archive-keyring \
    && apt-get install -y --no-install-recommends \
           postgresql-9.6 \
           postgresql-contrib-9.6 \
           libpg-hstore-perl \
           uuid-dev \
           graphviz \ 
           graphicsmagick \
           raptor2-utils \
           sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home -s /bin/bash gcis

COPY cpanfile *.PL MANIFEST* META.* .travis.yml *.md README.osx /home/gcis/

COPY bin /home/gcis/bin

COPY db /home/gcis/db

COPY eg /home/gcis/eg

COPY lib /home/gcis/lib

COPY t /home/gcis/t

WORKDIR /home/gcis/

RUN cpanm --installdeps --notest .

RUN perl Build.PL && ./Build && ./Build install

RUN cp eg/docker/Tuba.conf.sample ./Tuba.conf && mkdir /var/local/projects 

EXPOSE 8080

ENTRYPOINT ["hypnotoad", "-f", "bin/tuba"]
