use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build::Database;
BEGIN {
    eval qq{
    use Module::Build::Mojolicious clean_install => 1;
    push \@Module::Build::Database::PostgreSQL::ISA, 'Module::Build::Mojolicious';
    };
    die $@ if $@;
}
use File::ShareDir qw/dist_dir/;

my $builder = Module::Build::Database->new(
    install_base        => '/usr/local/gcis',
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
        'Module::Build' => 0.38,
        'Module::Build::Mojolicious' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Mojolicious::Plugin::YamlConfig' => 0,
        'Mojolicious' => '4.14',
        'YAML::Syck'  => 0,
        'YAML::XS'    => 0,
        'Rose::DB::Object' => 0,
        'DBIx::Simple' => 0,
        'DBIx::Custom' => 0,
        'SQL::Abstract' => 0,
        'SQL::Interp' => 0,
    },
    add_to_cleanup     => [ 'Tuba-*' ],
    create_makefile_pl => 'traditional',
);

# Temporary bootstrapping until we have real images; just check to see
# if this little symlink is in place.
my $dir = eval { dist_dir('Tuba'); };
if ($dir && !$@) {
    -l "$dir/public/img" or do {
        warn "\n\nPlease run ln -s /var/local/projects/raw/data/images $dir/public/img\n\n";
    };
}

$builder->create_build_script();
