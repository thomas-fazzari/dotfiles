package BashGuard::Delete;
use strict;
use warnings;
use Exporter 'import';
use List::Util       qw(any);
use BashGuard::Rules qw(first_reason arg arg_like);
use BashGuard::Shell qw(program_name operands expand_home);

our @EXPORT_OK = qw(deletion_risk);

my $RSYNC_DELETE  = qr/^--(?:del|delete(?:-[\w-]+)?|remove-source-files)$/;
my $DEVICE_OUTPUT = qr{^of=/dev/(?!(?:null|zero|full|stdout|stderr)$)};
my $DISKUTIL_WIPE = qr/^(?:erase|zero|random|secureErase|reformat|partition|split|merge|resize|delete|remove)/i;

# newfs_apfs, newfs_hfs and the other variants share the newfs entry
my %RULES = (
  rm       => ['rm on a root, home or parent directory removes it whole' => sub { too_broad(operands(@_)) }],
  find     => ['find -delete deletes files for good'                     => sub { arg('-delete') }],
  rsync    => ['rsync --delete deletes files for good'                   => sub { arg_like($RSYNC_DELETE) }],
  shred    => ['shred overwrites files for good'                         => sub {1}],
  dd       => ['dd writes straight to a device'                          => sub { arg_like($DEVICE_OUTPUT) }],
  newfs    => ['newfs formats a device'                                  => sub {1}],
  diskutil => ['diskutil can erase or repartition a disk'                => sub { arg_like($DISKUTIL_WIPE) }],
);

sub deletion_risk {
  my ($program, @args) = @_;
  my $name = program_name($program) =~ s/^newfs_\w+$/newfs/r;
  return first_reason($RULES{$name}, @args);
}

# Too broad to delete, even through the trash
sub too_broad {
  my @operands = @_;
  my @paths    = map { expand_home($_) =~ s{/\*$}{/}r =~ s{(?<=.)/+$}{}r } @operands;
  my $home     = $ENV{HOME} // '';
  return any { m{^/[^/]*$} || $_ eq $home || m{(?:^|/)\.\.$} || $_ eq '.' } @paths;
}

1;
