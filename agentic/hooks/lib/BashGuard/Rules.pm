package BashGuard::Rules;
use strict;
use warnings;
use Exporter 'import';
use List::Util qw(any pairfirst);

our @EXPORT_OK = qw(first_reason arg arg_like action flag);

our @ARGS;

# Rules are reason => condition pairs and the first match wins
# Conditions get the arguments in @_, the helpers below read them from @ARGS
sub first_reason {
  my ($rules, @args) = @_;
  local @ARGS = @args;
  my ($reason) = pairfirst { $b->(@ARGS) } @{$rules // []};
  return $reason // ();
}

sub arg {
  my @names  = @_;
  my %wanted = map { $_ => 1 } @names;
  return any { $wanted{$_} } @ARGS;
}

sub arg_like {
  my ($pattern) = @_;
  return any { $_ =~ $pattern } @ARGS;
}

# First argument, such as drop in git stash drop
sub action {
  my @names = @_;
  my $first = $ARGS[0] // return 0;
  return any { $_ eq $first } @names;
}

# Any spelling of an option given as --long or -l, with letters matching inside -abc clusters
sub flag {
  my @spellings = @_;
  my %longs     = map { $_ => 1 } grep {/^--/} @spellings;
  my @letters   = map { /^-(\w)$/ ? $1 : () } @spellings;
  for my $arg (@ARGS) {
    last if $arg eq '--';
    if ($arg =~ /^-(\w+)$/) {
      my $cluster = $1;
      return 1 if any { index($cluster, $_) >= 0 } @letters;
    }
    elsif ($arg =~ /^(--[\w-]+)(?:=|$)/) {
      return 1 if $longs{$1};
    }
  }
  return 0;
}

1;
