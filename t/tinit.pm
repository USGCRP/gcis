BEGIN {
    use FindBin;
    $ENV{TUBA_CONFIG} = "$FindBin::Bin/Tuba-test.conf";
}

1;

