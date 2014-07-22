
Global Change Information System [![Build Status](https://secure.travis-ci.org/USGCRP/gcis.png)](http://travis-ci.org/USGCRP/gcis)
================================

This is the HTML front end and API for the [Global Change Information System](http://data.globalchange.gov) (GCIS).

This portion of the GCIS is called Tuba.

Prerequisites :

    - PostgreSQL
    - Perl 5.10 or later
    - uuid-dev package
    - A recent raptor (<http://librdf.org/raptor>)

On Ubuntu 14.04, they can be installed with:

    - sudo apt-get install postgresql-contrib-9.3 libpg-hstore-perl \
      postgresql libuuid1 uuid-dev make openssl libssl-dev libpq-dev \
      graphviz libxml2 raptor2-utils curl cpanminus


Install of Perl prerequisites :

    curl -L http://cpanmin.us > cpanm
    chmod +x cpanm
    ./cpanm --installdeps .

Software installation :

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Database installation :

    ./Build dbinstall

Configuration :

    cp eg/Tuba.conf.sample Tuba.conf

Starting :

    hypnotoad tuba

