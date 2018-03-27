Global Change Information System
================================
[![Build Status](https://travis-ci.org/USGCRP/gcis.svg?branch=master)](https://travis-ci.org/USGCRP/gcis/branches) [![Coverage Status](https://img.shields.io/coveralls/USGCRP/gcis.svg)](https://coveralls.io/r/USGCRP/gcis)

This is the HTML front end and API for the [Global Change Information System](http://data.globalchange.gov) (GCIS).

This portion of the GCIS is called Tuba.

## Docker installation

[See Docker Readme](./README.docker.md)

## Mac installation

[See MacOS Readme](./README.osx)

## Linux installation

Prerequisites :

    - PostgreSQL 9.3+, 
      - requires addtional dev, contrib, and server packages
    - Perl 5.20
    - uuid dev package
    - OpenSSL dev package
    - A recent raptor (<http://librdf.org/raptor>)

On Ubuntu 14.04, they can be installed with:

    - sudo apt-get install postgresql-contrib-9.3 libpg-hstore-perl \
      postgresql-9.3 postgresql-server-dev-9.3 libuuid1 uuid-dev make \
      openssl libssl-dev libpq-dev graphviz libxml2 raptor2-utils curl \
      perlbrew
      
For CentOS, they can be installed with: 
 
    - sudo yum install openssl-devel uuid-devel make postgresql93-devel \
      postgresql93-contrib postgresql93-server postgresql93 graphviz \
      libxml2 raptor2-utils curl perlbrew

Instantiate Perlbrew environment:

    perlbrew init                 # complete the init instructions
    perlbrew install perl-5.20.0
    perlbrew install-cpanm
    perlbrew install-patchperl
    perlbrew switch perl-5.20.0

Clone the Repository :

    git clone https://github.com/USGCRP/gcis

Install of Perl prerequisites :

    cd gcis
    cpanm --installdeps .

Customize install_base (optional) :

    echo $(dirname $(dirname $(which perl)))
    vi Build.PL
    # use the ouput of the command above as the value for --install_base below
    # or create a file $HOME/.modulebuildrc, that contains :
    #       install     --install_base /your/directory/here

Software installation :

    perl Build.PL # --install_base=(see above) if using custom
    ./Build
    ./Build test
    ./Build install

Database configuration :

Add these directives to postgresql.conf, under "CUSTOMIZED OPTIONS" :

    audit.username = 'unknown'
    audit.note = ''

Database installation :

    sudo su - postgres -c "createuser -P -s -e $(whoami)"
    ./Build dbinstall

Configuration :

    cp eg/Tuba.conf.sample Tuba.conf
    sudo mkdir /var/local/projects
    sudo chown $(whoami):$(whoami) /var/local/projects

Starting :

    hypnotoad bin/tuba

Starting in dev mode :

    morbo -l http://0.0.0.0:3000 bin/tuba    

