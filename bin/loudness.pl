#!/usr/bin/env perl
# Measure loudness and true peak (EBU R128 summary only).
use strict;
use warnings;
use IPC::Open3 qw(open3);

# Checked here because the loop below only prints the summary, so ffmpeg's own error would not show
my $file = shift // '';
-f $file or die "Usage: loudness FILE\n";

# ffmpeg writes the report to stderr, merged here into $output.
my $pid = open3('<&STDIN', my $output, undef, 'ffmpeg', qw(-hide_banner -nostats -i),
  $file, qw(-filter_complex ebur128=peak=true:framelog=verbose -f null -));

my ($show, $done) = (0, 0);
while (my $line = <$output>) {
  $show ||= $line =~ /Summary:/;
  next if !$show || $done;
  print $line;
  $done = $line =~ /Peak:/;
}
waitpid $pid, 0;
exit($? == 0 ? 0 : ($? >> 8) || 1);
