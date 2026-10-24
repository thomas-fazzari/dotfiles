use strict;
use warnings;
use FindBin    qw($RealBin);
use IPC::Open2 qw(open2);
use JSON::PP;
use Test::More;

my $HOOK  = "$RealBin/../bash-guard.pl";
my $TRASH = "$ENV{HOME}/.claude/hooks/trash-rm.pl";

sub run_hook {
  my ($command) = @_;
  my $pid = open2(my $out, my $in, $^X, $HOOK);
  print $in encode_json({tool_input => {command => $command, description => 'kept', run_in_background => JSON::PP::true}
  });
  close $in;
  my $output = do { local $/; <$out> };
  waitpid $pid, 0;
  return $output eq '' ? {} : decode_json($output)->{hookSpecificOutput};
}

my @untouched = (
  'ls -la',
  'git rm --cached file',
  'docker run --rm alpine',
  'cargo rm serde',
  'git commit -m "drop x; rm y"',
  'git commit -m "git reset --hard"',
  'git commit -m "fix $(date)"',
  'ls # rm x',
  'cat <<EOF',
  'git reset --soft HEAD~1',
  'git checkout -b feature',
  'git restore --staged src/main.rs',
  'git clean -nd',
  'git push --force-with-lease',
  'git branch -d merged',
  'git stash pop',
  'npm install',
  'bun add zod',
  'mise use node@26',
  'find . -name "*.orig"',
);
is_deeply(run_hook($_), {}, "untouched: $_") for @untouched;

my @asks = (
  'git reset --hard HEAD~1',
  'git checkout -- src/main.rs',
  'git restore src/main.rs',
  'git clean -fdx',
  'git -C repo clean -f',
  'git push --force origin main',
  'git push -f',
  'git push origin +main',
  'git branch -D old',
  'git stash drop',
  'git status && git clean -f',
  '{ git reset --hard; }',
  'if git reset --hard; then :; fi',
  '! git reset --hard',
  'echo `git reset --hard`',
  'echo "$(git reset --hard)"',
  'echo "now: $(date)" && git reset --hard',
  'brew install jq',
  'sudo brew install jq',
  'npm install -g typescript',
  'bun add -g oxfmt',
  'cargo install ripgrep',
  'pip install requests',
  'uv tool install ruff',
  'mise use -g node@26',
  'find . -name "*.orig" -delete',
);
is(run_hook($_)->{permissionDecision}, 'ask', "asks: $_") for @asks;

my @rewrites = (
  ['rm -rf target/tmp',                    "$TRASH -rf target/tmp",                       'allow'],
  ['\rm x',                                "$TRASH x",                                    'allow'],
  ['/bin/rm -rf x',                        "$TRASH -rf x",                                'allow'],
  ['rm x 2>/dev/null',                     "$TRASH x 2>/dev/null",                        undef],
  ['cd x && rm -f a; ls',                  "cd x && $TRASH -f a; ls",                     undef],
  ['sudo rm -rf /tmp/x',                   "sudo $TRASH -rf /tmp/x",                      undef],
  ['FOO=1 rm x',                           "FOO=1 $TRASH x",                              undef],
  ['find . -name "*.orig" | xargs -0 rm',  "find . -name \"*.orig\" | xargs -0 $TRASH",   undef],
  ['find . -name "*.orig" -exec rm {} \;', "find . -name \"*.orig\" -exec $TRASH {} \\;", undef],
  ['echo $(rm x)',                         "echo \$($TRASH x)",                           undef],
  ['echo "$(rm -rf build)"',               "echo \"\$($TRASH -rf build)\"",               undef],
  ["echo 'rm a' && rm b",                  "echo 'rm a' && $TRASH b",                     undef],
  ['for f in *.tmp; do rm "$f"; done',     "for f in *.tmp; do $TRASH \"\$f\"; done",     undef],
  ['rm -rf x && git reset --hard',         "$TRASH -rf x && git reset --hard",            'ask'],
);
for my $case (@rewrites) {
  my ($command, $rewritten, $decision) = @$case;
  my $result = run_hook($command);
  is($result->{updatedInput}{command}, $rewritten, "rewrites: $command");
  is($result->{permissionDecision},    $decision,  "decision for: $command");
}

my $updated = run_hook('rm x')->{updatedInput};
is($updated->{description}, 'kept', 'rewrite keeps the other tool input fields');
ok($updated->{run_in_background}, 'rewrite keeps boolean fields');

done_testing;
