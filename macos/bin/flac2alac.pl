#!/usr/bin/env perl
# Convert all .flac files in the current directory to Apple Lossless (alac/*.m4a).
use strict;
use warnings;
use Cwd        qw(getcwd);
use File::Path qw(make_path);

my $interrupted = 0;
local $SIG{INT} = sub { $interrupted = 1 };

# Like system(), but Ctrl-C reaches our handler so the whole batch stops.
sub run {
  my @cmd = @_;
  my $pid = fork // die "fork: $!\n";
  if ($pid == 0) {
    exec {$cmd[0]} @cmd;
    exit 127;
  }
  waitpid $pid, 0;
  return $? == 0;
}

my @files = glob '*.flac';
if (!@files) {
  printf "No .flac files found in %s\n", getcwd();
  exit 0;
}

make_path('alac');
my ($converted, $skipped, $failed) = (0, 0, 0);
for my $file (@files) {
  my $output = 'alac/' . ($file =~ s/\.flac\z/.m4a/r);
  if (-e $output) {
    print "Skipped existing $output\n";
    $skipped++;
    next;
  }

  my $ok = run('ffmpeg', qw(-hide_banner -loglevel error -nostdin -n -i),
    $file, qw(-map 0:a:0 -map 0:v? -map_metadata 0 -c:a alac -c:v copy), $output);

  if ($interrupted) {
    unlink $output;
    print STDERR "Interrupted, removed partial $output\n";
    exit 130;
  }

  if ($ok) {
    print "Created $output\n";
    $converted++;
  }
  else {
    unlink $output;
    print STDERR "Failed $file\n";
    $failed++;
  }
}

printf "Converted: %d, skipped: %d, failed: %d\n", $converted, $skipped, $failed;
exit($failed ? 1 : 0);
