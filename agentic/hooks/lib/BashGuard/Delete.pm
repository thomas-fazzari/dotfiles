package BashGuard::Delete;
use strict;
use warnings;
use Exporter 'import';
use List::Util       qw(any);
use BashGuard::Rules qw(first_reason arg arg_like flag);
use BashGuard::Shell qw(program_name operands expand_home);

our @EXPORT_OK = qw(deletion_risk);

my $RSYNC_DELETE  = qr/^--(?:del|delete(?:-[\w-]+)?|remove-source-files)$/;
my $DEVICE_OUTPUT = qr{^of=/dev/(?!(?:null|zero|full|stdout|stderr)$)};
my $DISKUTIL_WIPE = qr/^(?:erase|zero|random|secureErase|reformat|partition|split|merge|resize|delete|remove)/i;

# mkfs.ext4, newfs_apfs and the other variants share the mkfs entry
my %RULES = (
  rm       => ['rm on a root, home or parent directory removes it whole' => sub { too_broad(operands(@_)) }],
  find     => ['find -delete deletes files for good'                     => sub { arg('-delete') }],
  rsync    => ['rsync --delete deletes files for good'                   => sub { arg_like($RSYNC_DELETE) }],
  shred    => ['shred overwrites files for good'                         => sub {1}],
  dd       => ['dd writes straight to a device'                          => sub { arg_like($DEVICE_OUTPUT) }],
  mkfs     => ['mkfs formats a device'                                   => sub {1}],
  wipefs   => ['wipefs erases filesystem signatures'                     => sub { !flag('--no-act', '-n') }],
  diskutil => ['diskutil can erase or repartition a disk'                => sub { arg_like($DISKUTIL_WIPE) }],
);

sub deletion_risk {
  my ($program, @args) = @_;
  my $name = program_name($program) =~ s/^(?:mkfs|mke2fs|newfs)(?:[._]\w+)?$/mkfs/r;
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
