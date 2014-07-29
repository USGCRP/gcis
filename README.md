
Global Change Information System 
[![Build Status](https://secure.travis-ci.org/USGCRP/gcis.png)](http://travis-ci.org/USGCRP/gcis) [![Coverage Status](https://img.shields.io/coveralls/USGCRP/gcis.svg)](https://coveralls.io/r/USGCRP/gcis)
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

Database configuration :

You may need to add these directives to postgresql.conf, under "CUSTOMIZED
OPTIONS" for some versions of postgreSQL :

    custom_variable_classes = 'audit'   # list of custom variable class names
    audit.username = 'unknown'
    audit.note = ''

Database installation :

    ./Build dbinstall

Configuration :

    cp eg/Tuba.conf.sample Tuba.conf

Starting :

    hypnotoad tuba

