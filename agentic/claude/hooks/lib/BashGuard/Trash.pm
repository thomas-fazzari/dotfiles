package BashGuard::Trash;
use strict;
use warnings;
use Exporter 'import';
use BashGuard::Shell qw(has_arg shell_quote);

our @EXPORT_OK = qw(is_rm trash_available rewrite_rm deletion_risk);

my $TRASH_RM = "$ENV{HOME}/.claude/hooks/trash-rm.pl";
my %RM_NAMES = map { $_ => 1 } qw(rm /bin/rm /usr/bin/rm);

sub is_rm {
    my ($program) = @_;
    return $RM_NAMES{$program};
}

sub trash_available { return -x '/usr/bin/trash' }

# Replaces each rm word, given as [start, end, text], with the trash helper
sub rewrite_rm {
    my ( $command, @words ) = @_;
    for my $word ( sort { $b->[0] <=> $a->[0] } @words ) {
        substr( $command, $word->[0], $word->[1] - $word->[0] ) =
          shell_quote($TRASH_RM);
    }
    return $command;
}

sub deletion_risk {
    my ( $program, @args ) = @_;
    return 'find -delete deletes files for good'
      if $program eq 'find' && has_arg( \@args, '-delete' );
    return;
}

1;
