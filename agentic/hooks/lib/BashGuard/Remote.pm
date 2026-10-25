package BashGuard::Remote;
use strict;
use warnings;
use Exporter 'import';
use BashGuard::Shell qw(program_name is_shell inline_script);

our @EXPORT_OK = qw(is_fetcher runs_unseen_code);

my %FETCHERS     = map { $_ => 1 } qw(curl wget);
my %INTERPRETERS = map { $_ => 1 } qw(python python3 perl node);

sub is_fetcher {
  my ($program) = @_;
  return $FETCHERS{program_name($program)};
}

# Code that never shows up in the command, so approving the command does not review it
sub runs_unseen_code {
  my ($program, @args) = @_;
  my $name   = program_name($program);
  my $script = inline_script($program, @args);
  return $script =~ /\$\(|`/     if defined $script;
  return ($args[0] // '') eq '<' if $name eq 'source' || $name eq '.';
  return reads_stdin(@args)      if is_shell($name)   || $INTERPRETERS{$name};
  return 0;
}

# Shells and interpreters given no script operand run whatever arrives on stdin
sub reads_stdin {
  my @args = @_;
  for my $arg (@args) {
    return 1 if $arg =~ /^(?:-|-s|<)$/;
    return 0 if $arg !~ /^-/;
  }
  return 1;
}

1;
