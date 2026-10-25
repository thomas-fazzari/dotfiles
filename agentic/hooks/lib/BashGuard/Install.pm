package BashGuard::Install;
use strict;
use warnings;
use Exporter 'import';
use BashGuard::Rules qw(first_reason action flag);
use BashGuard::Shell qw(program_name);

our @EXPORT_OK = qw(install_risk);

sub global { return flag('--global', '-g') }

my %RULES = (
  brew  => ['brew install installs software globally'    => sub { action('install') }],
  npm   => ['npm install -g installs software globally'  => sub { action(qw(i install add)) && global() }],
  bun   => ['bun add -g installs software globally'      => sub { action(qw(i install add)) && global() }],
  cargo => ['cargo install installs software globally'   => sub { action('install') }],
  pip   => ['pip install installs software globally'     => sub { action('install') }],
  uv    => ['uv tool install installs software globally' => sub { action('tool') && ($_[1] // '') eq 'install' }],
  mise  => ['mise use -g installs software globally'     => sub { action('use')  && global() }],
);
$RULES{pip3} = $RULES{pip};

sub install_risk {
  my ($program, @args) = @_;
  return first_reason($RULES{program_name($program)}, @args);
}

1;
