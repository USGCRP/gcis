# Note: this file was auto-generated by Module::Build::Compat version 0.4224
use ExtUtils::MakeMaker;
WriteMakefile
(
  'EXE_FILES' => [
                   'bin/hypnotoad.pid',
                   'bin/tuba',
                   'bin/tuba_generate_sitemap',
                   'bin/tuba_get_ontology',
                   'bin/tuba_start_httpd',
                   'bin/tuba_stop_httpd'
                 ],
  'NAME' => 'Tuba',
  'INSTALLDIRS' => 'site',
  'PREREQ_PM' => {
                   'Digest::SHA1' => 0,
                   'DBIx::Simple' => 0,
                   'Time::Duration' => 0,
                   'LWP::Protocol::https' => '6.07',
                   'Crypt::OpenSSL::RSA' => 0,
                   'Text::CSV_XS' => 0,
                   'JSON::XS' => 0,
                   'Rose::DB' => '0.772',
                   'JSON::WebToken' => 0,
                   'DBD::Pg' => '3.003',
                   'DBIx::Custom' => 0,
                   'Rose::DB::Object' => 0,
                   'Lingua::EN::Inflect' => 0,
                   'Scalar::Util' => 0,
                   'Text::Format' => 0,
                   'RDF::Query' => 0,
                   'Date::Parse' => 0,
                   'Captcha::reCAPTCHA' => '0.99',
                   'Algorithm::Permute' => 0,
                   'DBIx::Connector' => 0,
                   'IO::Socket::SSL' => 2,
                   'URI::Find' => 0,
                   'LWP::UserAgent' => 0,
                   'List::MoreUtils' => '0.427',
                   'Sort::Key' => 0,
                   'Number::Format' => 0,
                   'Mojolicious::Plugin::Mail' => '1.5',
                   'Pg::hstore' => 0,
                   'Path::Class' => 0,
                   'Mojolicious::Plugin::YamlConfig' => 0,
                   'YAML::Syck' => 0,
                   'Number::Bytes::Human' => 0,
                   'SQL::Abstract' => 0,
                   'Hash::Flatten' => 0,
                   'HTML::Restrict' => '2.002004',
                   'SQL::Interp' => 0,
                   'Mojolicious' => '6.08',
                   'Test::More' => 0,
                   'File::ShareDir' => '1.00',
                   'UUID::Tiny' => 0,
                   'Module::Build::Mojolicious' => 0,
                   'YAML::XS' => 0,
                   'Data::Rmap' => 0,
                   'String::Diff' => 0,
                   'RDF::Trine' => 0,
                   'Mojolicious::Plugin::InstallablePaths' => 0,
                   'YAML' => 0,
                   'DateTime::Format::Human::Duration' => 0
                 },
  'PL_FILES' => {},
  'VERSION_FROM' => 'lib/Tuba.pm'
)
;
