=head1 NAME

Tuba::Log -- set/get a logger

=head1 DESCRIPTION

In the main app :

   use Tuba::Log;
   set_logger(app->log)

Someplace else

    use Tuba::Log;
    loggger->info("hi!");

=cut

package Tuba::Log;
use Mojo::Util qw/monkey_patch/;

my $logger;

sub import {
    my $self = shift;
    my $into = caller;
    monkey_patch $into, logger => sub {
        $logger;
    };
}

sub set_logger {
    my $class = shift;
    $logger = shift;
}

1;
