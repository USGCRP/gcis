BEGIN {
    use FindBin;
    if ($ENV{TRAVIS}) {
        $ENV{TUBA_CONFIG} = "$FindBin::Bin/Tuba-travis.conf";
    }
    else {
        $ENV{TUBA_CONFIG} = "$FindBin::Bin/Tuba-test.conf";
    }
}

1;

