
Global Change Information System [![Build Status](https://secure.travis-ci.org/USGCRP/gcis.png)](http://travis-ci.org/USGCRP/gcis)
================================

This is the HTML front end and API for the [Global Change Information System](http://data.globalchange.gov) (GCIS).

This portion of the GCIS is called Tuba.

Prerequisites :

    - PostgreSQL
    - Perl 5.10 or later
    - uuid-dev package
    - A recent raptor (<http://librdf.org/raptor>)

On Ubuntu, the latter two can be installed with

  - sudo apt-get install libuuid1 uuid-dev raptor2-utils

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

