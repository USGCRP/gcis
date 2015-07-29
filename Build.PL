use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build::Database 0.47;
BEGIN {
    eval qq{
    use Module::Build::Mojolicious clean_install => 1;
    push \@Module::Build::Database::PostgreSQL::ISA, 'Module::Build::Mojolicious';
    };
    die $@ if $@;
}
use File::ShareDir qw/dist_dir/;

my $extra = $ENV{POSTGRES_91} ? qq[\ncustom_variable_classes = 'audit'] : "";

open my $fp, '< db/extra/audit.sql' or die "audit.sql :$!";
my $audit_sql = join '', <$fp>;
close $fp;

my $builder = Module::Build::Database->new(
    install_base        => '/usr/local/gcis',
    database_type       => 'PostgreSQL',
    database_options    => {
        name => "gcis",
        schema => "gcis_metadata",
        after_create => $audit_sql,
        append_to_conf => qq[
            audit.username = 'unknown'
            audit.note = ''
            $extra
        ],
    },
    module_name         => 'Tuba',
    license             => 'agpl_3',
    dist_version_from   => 'lib/Tuba.pm',
    dist_abstract       => "The Useful Backend API",
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0.38,
        'Module::Build::Mojolicious' => 0,
        'Module::Build::Database' => 0,
        'Mojolicious::Plugin::InstallablePaths' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Module::Build::Mojolicious' => 0,
        'Mojolicious::Plugin::InstallablePaths' => 0,
    },
    requires => {
        'LWP::UserAgent' => 0,
        'Number::Bytes::Human' => 0,
        'Mojolicious::Plugin::YamlConfig' => 0,
        'Mojolicious' => '6.08',
        'Number::Format' => 0,
        'YAML::Syck'  => 0,
        'YAML::XS'    => 0,
        'YAML'        => 0,
        'UUID::Tiny'  => 0,
        'Rose::DB' => '0.772',
        'Rose::DB::Object' => 0,
        'DBD::Pg' => '3.003',
        'Digest::SHA1' => 0,
        'DBIx::Simple' => 0,
        'DBIx::Custom' => 0,
        'DBIx::Connector' => 0,
        'RDF::Trine' => 0,
        'RDF::Query' => 0,
        'SQL::Abstract' => 0,
        'SQL::Interp' => 0,
        'Swagger2' => 0,
        'Date::Parse' => 0,
        'JSON::XS'    => 0,
        'Algorithm::Permute' => 0,
        'JSON::WebToken' => 0,
        'Crypt::OpenSSL::RSA' => 0,
        'Pg::hstore' => 0,
        'Sort::Key' => 0,
        'Text::CSV_XS' => 0,
        'Text::Format' => 0,
        'Time::Duration' => 0,
        'URI::Find' => 0,
        'YAML::XS' => 0,
        'String::Diff' => 0,
        'DateTime::Format::Human::Duration' => 0,
        'Mojolicious::Plugin::InstallablePaths' => 0,
        # 'RDF::Trine' => 0,
        # 'RDF::Query' => 0,
        'IO::Socket::SSL' => 2,
        'Lingua::EN::Inflect' => 0,
        'Path::Class' => 0,
        'Scalar::Util' => 0,
    },
    add_to_cleanup     => [ 'Tuba-*' ],
    create_makefile_pl => 'traditional',
    share_dir => { dist => ["lib/Tuba/files"] },
);

$builder->create_build_script();
