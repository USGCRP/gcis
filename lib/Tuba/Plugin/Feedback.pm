=head1 NAME

Tuba::Plugin::Feedback - Validating and Passing on Feedback

=head1 SYNOPSIS

 app->plugin('Feedback' => $config);

=head1 DESCRIPTION

Set up helper for validating the data in the feedback form and emailing it to us.

=cut

package Tuba::Plugin::Feedback;
use Mojo::Base qw/Mojolicious::Plugin/;
use Captcha::reCAPTCHA;
use HTML::Restrict;

use Tuba::Log;

sub register {
    my ($self, $app, $conf) = @_;

    my $captcha = Captcha::reCAPTCHA->new();
    my $private_key = $conf->{private_key};
    my $public_key = $conf->{public_key};

    $app->helper(captcha_form => sub {
        return $captcha->get_html_v2($public_key);
    });

    $app->helper(process_feedback => sub {
            my $c = shift;
            my $response = $c->param('g-recaptcha-response') ? $c->param('g-recaptcha-response') : ' ';
            my $result = $captcha->check_answer_v2($private_key, $response, $ENV{REMOTE_ADDR});

            if ( $result->{is_valid} ) {
               logger->debug("Captcha failure: " . $result->{error});
               return 0;
            }

            my $stripper = HTML::Restrict->new();

            my $name         = $stripper->process( $c->param('name') ? $c->param ('name') : 'Unknown' );
            my $email        = $stripper->process( $c->param('email') ? $c->param ('email') : 'Unknown' );
            my $organization = $stripper->process( $c->param('organization') ? $c->param('organization') : 'Not Provided' );
            my $issue_type   = $stripper->process( $c->param('issue_type') ? $c->param ('issue_type') : 'Unknown' );
            my $message      = $stripper->process( $c->param('message') ? $c->param ('message') : 'No message provided.' );

            my $subject = "New Message From $name";
            my $body = <<"ENDOFBODY";
Feedback recieved about GCIS<br/><br/>

        Name: $name          <br/>
       Email: $email         <br/>
Organization: $organization  <br/>
  Issue Type: $issue_type    <br/>
<br/>
Message:<br/>
---<br/>
<br/>
$message<br/>
<br/>
---<br/>
ENDOFBODY
            $app->mail(
                  to      => $conf->{to},
                  subject => $subject,
                  data    => $body,
            );

            return 1;
    } );
}

1;
