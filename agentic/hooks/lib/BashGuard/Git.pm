package BashGuard::Git;
use strict;
use warnings;
use Exporter 'import';
use BashGuard::Rules qw(first_reason arg arg_like action flag);

our @EXPORT_OK = qw(git_risk);

my %GLOBAL_OPTIONS_WITH_VALUE = map { $_ => 1 } qw(-C -c --git-dir --work-tree --namespace);

sub forced      { return flag('--force',            '-f') }
sub leased      { return flag('--force-with-lease', '--force-if-includes') }
sub staged_only { return flag('--staged',           '-S') && !flag('--worktree', '-W') }

my %RULES = (
  reset => [
    'git reset --hard discards uncommitted changes'     => sub { flag('--hard') },
    'git reset --merge can discard uncommitted changes' => sub { flag('--merge') },
  ],
  checkout => [
    'git checkout can discard uncommitted changes' => sub { forced() || arg('--', '.') || flag('--pathspec-from-file') }
  ],
  switch  => ['git switch --force discards uncommitted changes' => sub { forced() || flag('--discard-changes') }],
  restore => ['git restore discards uncommitted changes'        => sub { !staged_only() }],
  clean   => ['git clean deletes untracked files for good'      => sub { !flag('--dry-run', '-n') }],
  rm   => ['git rm --force discards uncommitted changes' => sub { forced() && !flag('--cached', '--dry-run', '-n') }],
  push => [
    'git push --mirror can overwrite and delete remote refs' => sub { flag('--mirror') },
    'git push --force can overwrite remote commits'          => sub { forced() || (arg_like(qr/^\+/) && !leased()) },
    'git push --delete deletes remote refs'                  => sub { flag('--delete', '-d') || arg_like(qr/^:./) },
  ],
  branch => ['git branch -D deletes unmerged commits' => sub { flag('-D') || (forced() && flag('--delete', '-d')) }],
  stash  => [
    'git stash drop deletes stashed changes'      => sub { action('drop') },
    'git stash clear deletes all stashed changes' => sub { action('clear') },
  ],
  worktree => ['git worktree remove --force discards uncommitted changes' => sub { action('remove') && forced() }],
  rebase   => ['git rebase --abort discards conflict resolutions'         => sub { flag('--abort') }],
  merge    => ['git merge --abort discards conflict resolutions'          => sub { flag('--abort') }],
  tag      => ['git tag --delete deletes tags'                            => sub { flag('--delete', '-d') }],
  reflog   => ['git reflog delete and expire remove recovery history'     => sub { action('delete', 'expire') }],
);

sub git_risk {
  my @args = @_;
  while (@args && $args[0] =~ /^-/) {
    my $flag = shift @args;
    shift @args if $GLOBAL_OPTIONS_WITH_VALUE{$flag};
  }
  my $subcommand = shift(@args) // return;
  return first_reason($RULES{$subcommand}, @args);
}

1;
