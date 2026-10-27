package BashGuard::Read;
use strict;
use warnings;
use Exporter 'import';
use Cwd              qw(abs_path getcwd);
use List::Util       qw(all any);
use BashGuard::Rules qw(first_reason flag);
use BashGuard::Shell qw(is_piped program_name operands expand_home);

our @EXPORT_OK = qw(read_risk leading_cd);

# find tests the file tools cannot run: times, sizes, owners, permissions, links
my $FIND_METADATA
  = qr/^-(?:[amc](?:min|time)|newer\w*|size|perm|empty|n?user|n?group|[ug]id|links|inum|samefile|ls|f?printf)$/;

# sed, awk and grep take a script or pattern first, so a second operand is a file
my %RULES;
$RULES{$_}   = ["$_ walks the file system" => sub {1}] for qw(fd tree rg ag);
$RULES{find} = ['find walks the file system' => sub { !finds_metadata(@_) }];
$RULES{$_}   = ["$_ prints files"   => sub { operands(@_) > 0 }] for qw(cat head tail less more nl bat);
$RULES{$_}   = ["$_ works on files" => sub { operands(@_) > 1 }] for qw(sed awk gawk);
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

sub resolve {
  my ($path, $dir) = @_;
  $path = expand_home($path);
  return $path =~ m{^/} ? $path : "$dir/$path";
}

# cd DIR at the start of a chain runs the rest of it from DIR
sub leading_cd {
  my ($commands) = @_;
  my ($program, @args) = map { $_->[2] } @{$commands->[0] // []};
  return if !defined $program || $program ne 'cd' || @args != 1 || $args[0] eq '-' || $args[0] =~ /[\$`*?]/;
  my $dir = resolve($args[0], getcwd());
  return unless -d $dir;
  return $dir;
}

# find walks its leading operands, the others the operands after their pattern
sub search_operands {
  my ($name, @args) = @_;
  if ($name eq 'find') {
    my @paths;
    for my $arg (@args) {
      last if $arg =~ /^[-(!]/;
      push @paths, $arg;
    }
    return @paths;
  }
  my (undef, @paths) = operands(@args);
  return @paths;
}

# Operands that name nothing on disk are option values, such as rg -g globs
sub search_paths {
  my ($dir, $name, @args) = @_;
  my @paths = grep {-e} map { resolve($_, $dir) } search_operands($name, @args);
  return @paths ? @paths : $dir;
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
  my $real   = abs_path($path) // return 0;
  my $root   = project_root();
  return 1 if index("$real/", "$root/") != 0;
  return $IN_GIT && system('git', '-C', $root, 'check-ignore', '-q', '--', $real) == 0;
}

# Reading and searching files is the job of the agent's own file tools
# A command fed by a pipe filters output instead, and command -v only looks a program up
sub read_risk {
  my ($words, $position, $workdir) = @_;
  my @before = map { program_name($_->[2]) } @{$words}[0 .. $position - 1];
  return if $position >= 2 && $before[-2] eq 'command' && $before[-1] =~ /^-[vV]$/;
  my ($program, @args) = map { $_->[2] } @{$words}[$position .. $#$words];

  # xargs appends the file names it reads from the pipe
  my $via_xargs = any { $_ eq 'xargs' } @before;
  return if is_piped($words) && !$via_xargs;
  push @args, '{}' if $via_xargs;

  my $name   = program_name($program);
  my $reason = first_reason($RULES{$name}, @args) // return;

  # A path the shell has yet to expand could be anywhere
  if ($SEARCHES{$name}) {
    return if any { expand_home($_) =~ /\$/ } search_operands($name, @args);
    return if all { out_of_file_tools_reach($_) } search_paths($workdir // getcwd(), $name, @args);
  }
  return "$reason: use your file read, search and listing tools instead";
}

1;
