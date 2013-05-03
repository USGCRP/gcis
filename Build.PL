use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tuba',
    license             => 'perl',
    dist_version_from   => 'lib/Tuba.pm',
    dist_abstract       => "The Useful Backend API",
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Mojolicious::Plugin::YamlConfig' => 0,
        'Mojolicious' => 0,
        'YAML::Syck'  => 0,
        'YAML::XS'    => 0,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Tuba-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
