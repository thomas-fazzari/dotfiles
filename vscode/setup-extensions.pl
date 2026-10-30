#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);

open my $list, '<', "$RealBin/extensions.txt" or die "extensions.txt: $!\n";
chomp(my @extensions = grep {/\S/} <$list>);
close $list;

my @failed = grep { system('code-insiders', '--install-extension', $_, '--force') != 0 } @extensions;
die "Failed to install: @failed\n" if @failed;
