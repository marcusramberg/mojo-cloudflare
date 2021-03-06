use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Mojo::Cloudflare',
  ABSTRACT_FROM => 'lib/Mojo/Cloudflare.pm',
  VERSION_FROM => 'lib/Mojo/Cloudflare.pm',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
    'Mojolicious' => 4.30,
  },
  BUILD_REQUIRES => {
    'Test::More' => 0.90,
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://metacpan.org/release/Mojo-Cloudflare',
      bugtracker => 'https://github.com/jhthorsen/mojo-cloudflare/issues',
      repository => 'https://github.com/jhthorsen/mojo-cloudflare.git',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
  #MIN_PERL_VERSION => 5.10,
  #EXE_FILES => ['bin/my-app'],
);
