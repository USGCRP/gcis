
Global Change Information System
build [![Build Status](https://secure.travis-ci.org/bduggan/gcis.png)](http://travis-ci.org/bduggan/gcis)
================================

This is the HTML front end and API for the Global Change Information System (GCIS).

This portion of the GCIS is called Tuba.

Prerequisites can be installed using cpanminus (http://cpanmin.us), e.g.

   curl -L http://cpanmin.us > cpanm
   chmod +x cpanm
   ./cpanm --installdeps .

Installation of the software uses the CPAN method :

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Also, to install the database :

    ./Build dbinstall

Configuration :

   cp eg/Tuba.conf.sample Tuba.conf

Starting :

   hypnotoad tuba

