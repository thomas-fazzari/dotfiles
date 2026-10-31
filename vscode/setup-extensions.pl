#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);

open my $list, '<', "$RealBin/extensions.txt" or die "extensions.txt: $!\n";
chomp(my @extensions = grep {/\S/} <$list>);
close $list;

my $attempts = 3;

sub install {
  my ($extension) = @_;
  for my $attempt (1 .. $attempts) {
    return 1           if system('code', '--install-extension', $extension, '--force') == 0;
    sleep 2 * $attempt if $attempt < $attempts;
  }
  return 0;
}

my @failed = grep { !install($_) } @extensions;
die "Failed to install: @failed\n" if @failed;
