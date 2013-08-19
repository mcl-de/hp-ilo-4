package HP::iLO::4;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.01';

###############################################################################
#
# new()
#
sub new {
	my $class = shift;
	my $parm = shift;

	unless (
		defined($parm->{Host}) && $parm->{Host}
	) {
		return;
	}

	my $self = {
		Host		=> $parm->{Host},
		Username	=> undef,
		Password	=> undef,

		_session	=> '',
		_loggedIn	=> 0,
		_ua			=> new LWP::UserAgent(
			cookie_jar	=> {},
			ssl_opts	=> {
				verify_hostname => 0
			}
		)
	};

	bless($self, $class);

	return $self;
}

sub login {
	my $self = shift;
	my $parm = shift;

	if (
		$self->{_loggedIn} == 0
		&& defined($parm->{Username}) && $parm->{Username}
		&& defined($parm->{Password}) && $parm->{Password}
	) {
		my $response = $self->{_ua}->post(
			'https://'.$self->{Host}.'/json/login_session',
			Content	=> '{"method":"login","user_login":"'.$parm->{Username}.'","password":"'.$parm->{Password}.'"}'
		);
		if ($response->is_success()) {
			my $json = JSON->new->decode($response->decoded_content());
			if (defined($json->{session_key}) && $json->{session_key}) {
				$self->{_session} = $json->{session_key};
				$self->{_loggedIn} = 1;
			}
			return 0;
		}
		else {
			die $response->status_line();
		}
	}

	return 1;
}

sub logout {
	my $self = shift;

	if (
		$self->{_loggedIn} == 1
	) {
		my $response = $self->{_ua}->post(
			'https://'.$self->{Host}.'/json/login_session',
			Content	=> '{"method":"logout","session_key":"'.$self->{_session}.'"}'
		);
		if ($response->is_success()) {
			$self->{_session} = '';
			$self->{_loggedIn} = 0;
			return 0;
		}
		else {
			die $response->status_line();
		}
	}

	return 1;
}

sub get {
	my $self = shift;
	my $parm = shift;

	if (
		$self->{_loggedIn} == 1
		&& defined($parm->{url}) && $parm->{url}
	) {
		my $response = $self->{_ua}->get('https://'.$self->{Host}.'/json/'.$parm->{url});
		if ($response->is_success()) {
			return JSON->new->decode($response->decoded_content());
		}
		else {
			die $response->status_line();
		}
	}

	return;
}

1;