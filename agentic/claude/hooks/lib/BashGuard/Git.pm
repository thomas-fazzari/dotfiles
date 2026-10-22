package BashGuard::Git;
use strict;
use warnings;
use Exporter 'import';
use List::Util       qw(any);
use BashGuard::Shell qw(has_arg has_short_flag);

our @EXPORT_OK = qw(git_risk);

sub git_risk {
    my @args = @_;
    while ( @args && $args[0] =~ /^-/ ) {
        my $flag = shift @args;
        shift @args if $flag eq '-C' || $flag eq '-c';
    }
    my $subcommand = shift(@args) // return;

    if ( $subcommand eq 'reset' ) {
        return 'git reset --hard discards uncommitted changes'
          if has_arg( \@args, '--hard' );
    }
    elsif ( $subcommand eq 'checkout' ) {
        return 'git checkout can discard uncommitted changes'
          if has_arg( \@args, '--', '.', '-f', '--force' );
    }
    elsif ( $subcommand eq 'restore' ) {
        my $staged_only = has_arg( \@args, '--staged', '-S' )
          && !has_arg( \@args, '--worktree', '-W' );
        return 'git restore discards uncommitted changes' unless $staged_only;
    }
    elsif ( $subcommand eq 'clean' ) {
        my $dry_run =
          has_arg( \@args, '--dry-run' ) || has_short_flag( \@args, 'n' );
        return 'git clean deletes untracked files for good' unless $dry_run;
    }
    elsif ( $subcommand eq 'push' ) {
        my $forced =
             has_arg( \@args, '--force' )
          || has_short_flag( \@args, 'f' )
          || any { /^\+/ } @args;
        my $leased = any { /^--force-(?:with-lease|if-includes)/ } @args;
        return 'git push --force can overwrite remote commits'
          if $forced && !$leased;
    }
    elsif ( $subcommand eq 'branch' ) {
        my $force_delete = has_short_flag( \@args, 'd' )
          && ( has_arg( \@args, '--force' ) || has_short_flag( \@args, 'f' ) );
        return 'git branch -D deletes unmerged commits'
          if has_short_flag( \@args, 'D' ) || $force_delete;
    }
    elsif ( $subcommand eq 'stash' ) {
        my $action = $args[0] // '';
        return "git stash $action deletes stashed changes"
          if $action eq 'drop' || $action eq 'clear';
    }
    return;
}

1;
