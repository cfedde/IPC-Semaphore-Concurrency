package IPC::Semaphore::Concurrency;

use 5.008008;
use strict;
use warnings;

use Carp;
use POSIX qw(O_WRONLY O_CREAT O_NONBLOCK O_NOCTTY);
use IPC::SysV qw(ftok IPC_NOWAIT IPC_CREAT IPC_EXCL S_IRUSR S_IWUSR S_IRGRP S_IWGRP S_IROTH S_IWOTH SEM_UNDO);
use IPC::Semaphore;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.01';

sub new {
	my $class = shift;

	my %args;
	if (@_ == 1) {
		# Only one required argument
		$args{'path'} = shift;
	} else {
		%args = @_;
	}

	if (!exists($args{'path'})) {
		carp "Must supply a path!"; #TODO: Allow private semaphores
		return undef;
	}
	# Set defaults
	$args{'project'} ||= 0;
	$args{'count'}   ||= 1;
	$args{'value'}   ||= 1; # TODO: allow array (one value per semaphore)
	$args{'touch'}   ||= 1;

	my $self = bless {}, $class;
	$self->{'_args'} = { %args };

	$self->_touch() if (!-f $self->{'_args'}->{'path'} || $self->{'_args'}->{'touch'}) or return undef;
	$self->{'_args'}->{'key'} = $self->_ftok() or return undef;

	$self->{'_args'}->{'sem'} = $self->_create($self->key()) or return undef;

	return $self;
}

# Internal functions
sub _touch {
	my $self = shift;
	sysopen(my $fh, $self->{'_args'}->{'path'}, O_WRONLY|O_CREAT|O_NONBLOCK|O_NOCTTY) or carp "Can't create ".$self->{'_args'}->{'path'}.": $!" and return 0;
	utime(undef, undef, $self->{'_args'}->{'path'}) if ($self->{'_args'}->{'auto_touch'});
	close $fh or carp "Can't close ".$self->{'_args'}->{'path'}.": $!" and return 0;
	return 1;
}

sub _ftok {
	my $self = shift;
	return ftok($self->{'_args'}->{'path'}, $self->{'_args'}->{'proj'}) or carp "Can't create semaphore key: $!" and return undef;
}

sub _create {
	my $self = shift;
	my $key = shift;
	# Presubably the semaphore exists already, so try using it right away
	my $sem = IPC::Semaphore->new($key, 0, 0);
	if (!defined($sem)) {
		# Creatie a new semaphore...
		$sem = IPC::Semaphore->new($key, $self->{'_args'}->{'count'}, IPC_CREAT|IPC_EXCL|S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
		if (!defined($sem)) {
			# Make sure another process did not create it in our back
			$sem = IPC::Semaphore->new($key, 0, 0) or carp "Semaphore creation failed!\n";
		} else {
			# If we created the semaphore now we assign its initial value
			for (my $i=0; $i<$self->{'_args'}->{'count'}; $i++) { # TODO: Support array - see above
				$sem->op($i, $self->{'_args'}->{'value'}, 0);
			}
		}
	}
	# Return whatever last semget call got us
	return $sem;
}

# External API

sub getall {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->getall();
}

sub getval {
	my $self = shift;
	my $nsem = shift or 0;
	return $self->{'_args'}->{'sem'}->getval($nsem);
}

sub getncnt {
	my $self = shift;
	my $nsem = shift or 0;
	return $self->{'_args'}->{'sem'}->getncnt($nsem);
}

sub setall {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->setall(@_);
}

sub setval {
	my $self = shift;
	my ($nsem, $val) = @_;
	return $self->{'_args'}->{'sem'}->setval($nsem, $val);
}

sub stat {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->stat();
}

sub key {
	my $self = shift;
	return $self->{'_args'}->{'key'};
}

sub acquire {
	my $self = shift;

        my %args;
        if (@_ >= 1 && $_[0] =~ /^\d+$/) {
		# Positional arguments
		($args{'sem'}, $args{'wait'}, $args{'max'}, $args{'undo'}) = @_;
	} else {
		%args = @_;
	}
	# Defaults
	$args{'sem'}  ||= 0;
	$args{'wait'} ||= 0;
	$args{'max'}  ||= 0;
	$args{'undo'} ||= 1;

	my $sem = $self->{'_args'}->{'sem'};
	my $flags = IPC_NOWAIT;
	$flags |= SEM_UNDO if ($args{'undo'});

	my $ret;
	if (($ret = $sem->op($args{'sem'}, -1, $flags))) {
		return $ret;
	} elsif ($args{'wait'}) {
		return $ret if ($args{'max'} && $self->getncnt($args{'sem'}) >= $args{'max'});
		# Remove NOWAIT and block
		$flags ^= IPC_NOWAIT;
		return $sem->op($args{'sem'}, -1, $flags);
	}
	return $ret;
}

sub release {
	my $self = shift;
	my $number = shift || 0;
	return $self->{'_args'}->{'sem'}->op($number, 1, 0);
}

sub remove {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->remove();
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

IPC::Semaphore::Concurrency - Perl extension for blah blah blah

=head1 SYNOPSIS

  use IPC::Semaphore::Concurrency;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for IPC::Semaphore::Concurrency, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>root@slackware.lanE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
