FROM perl:5.20

MAINTAINER Andrew Buddenberg

ENV PERL5LIB /usr/share/perl5

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-contrib-9.4 \
    libpg-hstore-perl \
    postgresql \
    uuid-dev \
    graphviz \ 
    raptor2-utils \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home -s /bin/bash gcis

COPY . /home/gcis/

WORKDIR /home/gcis/

RUN cpanm --installdeps --notest .

RUN perl Build.PL && ./Build && ./Build install

RUN cp eg/Tuba.conf.sample ./Tuba.conf && mkdir /var/local/projects 

EXPOSE 8080

CMD hypnotoad -f bin/tuba


