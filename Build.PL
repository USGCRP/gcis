use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build::Database;

my $builder = Module::Build::Database->new(
    database_type       => 'PostgreSQL',
    database_options    => {
        name => "gcis",
        schema => "gcis_metadata",
    },
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
        'Rose::DB::Object' => 0,
        'DBIx::Simple' => 0,
        'SQL::Abstract' => 0,
        'SQL::Interp' => 0,
    },
    add_to_cleanup     => [ 'Tuba-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
