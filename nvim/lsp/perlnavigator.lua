return {
  settings = {
    perlnavigator = {
      -- Perl::Critic and Perl::Tidy are installed there
      perlPath = vim.fn.has "mac" == 1 and "/opt/homebrew/bin/perl" or "/usr/bin/perl",
    },
  },
}
