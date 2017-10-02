FROM perl:5.22.2

LABEL authors="Andrew Buddenberg, Kathryn Tipton"
LABEL version="1.0.1"

ENV PERL5LIB /usr/share/perl5

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-contrib-9.4 \
    libpg-hstore-perl \
    postgresql-9.4 \
    uuid-dev \
    graphviz \ 
    raptor2-utils \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home -s /bin/bash gcis

COPY *.PL MANIFEST* META.* .travis.yml *.md README.osx /home/gcis/

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


