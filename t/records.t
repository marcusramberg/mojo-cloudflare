use Mojo::Base -base;
use Test::More;
use Mojo::Cloudflare;

plan skip_all => 'TEST_ONLINE="zone|email|key" Need to be set' unless $ENV{TEST_ONLINE};

my @args = split '\|', $ENV{TEST_ONLINE};
my $t = Mojo::Cloudflare->new(zone => $args[0], email => $args[1], key => $args[2]);
my($json, $record);

{
  $json = $t->records;

  ok defined $json->get('/count'), 'records: /count';
  ok $json->get('/count'), 'records: /count';
  ok $json->contains('/has_more'), 'records: /has_more';
  ok $json->get('/objs'), 'records: /objs';

  for(@{ $json->get('/objs') }) {
    next unless $_->{name} =~ /^direct\./;
    $record = $_;
  }

  ok $record, 'Found direct.foo.com record';
  ok $record->{rec_id}, 'record: rec_id';
}

done_testing;
