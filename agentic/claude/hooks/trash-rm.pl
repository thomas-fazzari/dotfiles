#!/usr/bin/env perl
# Stands in for rm (moves the operands to the trash)
use strict;
use warnings;

my $force = 0;
while ( @ARGV && $ARGV[0] =~ /^-./ ) {
    my $flag = shift @ARGV;
    last       if $flag eq '--';
    $force = 1 if $flag eq '--force' || $flag =~ /^-[^-]*f/;
}

my $status = 0;
my @existing;
for my $path (@ARGV) {
    if ( -e $path || -l $path ) {
        push @existing, $path;
    }
    elsif ( !$force ) {
        warn "rm: $path: No such file or directory\n";
        $status = 1;
    }
}

$status = 1 if @existing && system( '/usr/bin/trash', @existing ) != 0;
exit $status;
