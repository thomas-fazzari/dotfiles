package BashGuard::Install;
use strict;
use warnings;
use Exporter 'import';
use BashGuard::Shell qw(has_arg);

our @EXPORT_OK = qw(install_risk);

sub install_risk {
  my ($program, @args) = @_;
  my $subcommand = $args[0] // '';
  my $global     = has_arg(\@args, '-g', '--global');
  my $risk       = "$program $subcommand installs software globally";

  return $risk if $program eq 'brew'        && $subcommand eq 'install';
  return $risk if $program =~ /^(pacman|paru|yay)$/ && $subcommand =~ /^-[SU](?!\w*[silgpc])/;
  return $risk if $program =~ /^(npm|bun)$/ && $subcommand =~ /^(i|install|add)$/ && $global;
  return $risk if $program eq 'cargo'       && $subcommand eq 'install';
  return $risk if $program =~ /^pip3?$/     && $subcommand eq 'install';
  return 'uv tool install installs software globally'
    if $program eq 'uv' && $subcommand eq 'tool' && ($args[1] // '') eq 'install';
  return $risk if $program eq 'mise' && $subcommand eq 'use' && $global;
  return;
}

1;
