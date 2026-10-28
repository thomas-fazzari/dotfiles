package BashGuard::Secret;
use strict;
use warnings;
use Exporter 'import';
use File::Basename   qw(basename);
use BashGuard::Shell qw(expand_home);

our @EXPORT_OK = qw(secret_risk);

my $HOME = $ENV{HOME} // '';

my $SECRET_NAME = qr{^(?:
    \.env(?!\.(?:example|sample|template|tpl)(?:\.|$))(?:\..+)?
  | \.netrc | \.git-credentials
  | id_(?:rsa|ecdsa|ed25519)(?:[-_.](?!pub$).*)?
  | .+\.(?:pem|key|p12)
)$}x;

my $SECRET_HOME_PATH = qr{^\Q$HOME\E/(?:
    \.ssh(?:/|$)(?!.*\.pub$)
  | \.config/gh/hosts\.yml
  | \.claude/\.credentials\.json
  | \.pi/agent/auth\.json
)}x;

sub secret_risk {
  my @args = @_;
  for my $arg (@args) {

    # Paths also hide behind an option (--env-file=.env)
    my $path = expand_home($arg =~ s/^--?[\w-]+=//r);
    return "$arg may hold secrets" if basename($path) =~ $SECRET_NAME || $path =~ $SECRET_HOME_PATH;
  }
  return;
}

1;
