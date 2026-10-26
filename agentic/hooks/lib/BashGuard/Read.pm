package BashGuard::Read;
use strict;
use warnings;
use Exporter 'import';
use Cwd              qw(abs_path getcwd);
use List::Util       qw(all any);
use BashGuard::Rules qw(first_reason flag);
use BashGuard::Shell qw(is_piped program_name operands expand_home);

our @EXPORT_OK = qw(read_risk);

# find tests the file tools cannot run: times, sizes, owners, permissions, links
my $FIND_METADATA
  = qr/^-(?:[amc](?:min|time)|newer\w*|size|perm|empty|n?user|n?group|[ug]id|links|inum|samefile|ls|f?printf)$/;

# sed, awk and grep take a script or pattern first, so a second operand is a file
# ls -l and find on metadata show what the file tools cannot, unless ls also recurses
my %RULES;
$RULES{$_}   = ["$_ walks the file system"   => sub {1}] for qw(fd tree rg ag);
$RULES{find} = ['find walks the file system' => sub { !finds_metadata(@_) }];
$RULES{ls}   = ['ls lists files'             => sub { !flag('-l') || flag(qw(-R --recursive)) }];
$RULES{$_}   = ["$_ prints files"            => sub { operands(@_) > 0 }] for qw(cat head tail less more nl bat);
$RULES{$_}   = ["$_ works on files"          => sub { operands(@_) > 1 }] for qw(sed awk gawk);
$RULES{$_}   = ["$_ searches files" => sub { operands(@_) > 1 || flag(qw(-r -R --recursive --dereference-recursive)) }]
  for qw(grep egrep fgrep);

# The file tools only search what git tracks or could track inside the project
my %SEARCHES = map { $_ => 1 } qw(find fd rg ag grep egrep fgrep);

my ($PROJECT_ROOT, $IN_GIT);

sub finds_metadata {
  my @args = @_;
  for my $index (0 .. $#args) {
    return 1 if $args[$index] =~ $FIND_METADATA;
    return 1 if $args[$index] eq '-type' && ($args[$index + 1] // 'f') ne 'f';
  }
  return 0;
}

# find walks its leading operands, the others the operands that exist, and all of them . by default
sub search_paths {
  my ($name, @args) = @_;
  my @paths;
  if ($name eq 'find') {
    for my $arg (@args) {
      last if $arg =~ /^[-(!]/;
      push @paths, $arg;
    }
  }
  else {
    @paths = grep { -e expand_home($_) } operands(@args);
  }
  return @paths ? @paths : '.';
}

sub project_root {
  return $PROJECT_ROOT if defined $PROJECT_ROOT;
  chomp(my $top = `git rev-parse --show-toplevel 2>/dev/null`);
  $IN_GIT       = $top ne '';
  $PROJECT_ROOT = abs_path($IN_GIT ? $top : getcwd()) // getcwd();
  return $PROJECT_ROOT;
}

sub out_of_file_tools_reach {
  my ($path) = @_;
  my $real   = abs_path(expand_home($path)) // return 0;
  my $root   = project_root();
  return 1 if index("$real/", "$root/") != 0;
  return $IN_GIT && system('git', '-C', $root, 'check-ignore', '-q', '--', $real) == 0;
}

# Reading and searching files is the job of the agent's own file tools
# A command fed by a pipe filters output instead, and command -v only looks a program up
sub read_risk {
  my ($words, $position) = @_;
  my @before = map { program_name($_->[2]) } @{$words}[0 .. $position - 1];
  return if $position >= 2 && $before[-2] eq 'command' && $before[-1] =~ /^-[vV]$/;
  my ($program, @args) = map { $_->[2] } @{$words}[$position .. $#$words];

  # xargs appends the file names it reads from the pipe
  my $via_xargs = any { $_ eq 'xargs' } @before;
  return if is_piped($words) && !$via_xargs;
  push @args, '{}' if $via_xargs;

  my $name   = program_name($program);
  my $reason = first_reason($RULES{$name}, @args) // return;

  # Paths ignored by git or outside the project are out of the search tools' reach
  return if $SEARCHES{$name} && all { out_of_file_tools_reach($_) } search_paths($name, @args);
  return "$reason: use your file read, search and listing tools instead";
}

1;
