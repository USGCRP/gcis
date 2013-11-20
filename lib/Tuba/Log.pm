=head1 NAME

Tuba::Log -- set/get a logger

=head1 SYNOPSIS

In the main app :

   use Tuba::Log;
   set_logger(app->log)

Someplace else

    use Tuba::Log;
    logger->info("hi!");
    logger->info("hi!",dumpit($var));

=head1 DESCRIPTION

Imports logger, set_logger and dumpit.  See above.

=cut

package Tuba::Log;
use Mojo::Util qw/monkey_patch/;
use Data::Dumper;

my $logger;

sub import {
    my $self = shift;
    my $into = caller;
    monkey_patch $into, logger => sub {
        $logger;
    };
    monkey_patch $into, dumpit => sub {
        Dumper(shift);
    };
}

sub set_logger {
    my $class = shift;
    $logger = shift;
}

1;
