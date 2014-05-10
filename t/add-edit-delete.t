use t::Helper;

plan skip_all => 'TEST_ONLINE="zone|email|key" Need to be set' unless $ENV{TEST_ONLINE};

my @args = split '\|', $ENV{TEST_ONLINE};
my $cf = Mojo::Cloudflare->new(zone => $args[0], email => $args[1], key => $args[2], api_url => '/api_json', _ua => $t->ua);
my $id = $ENV{TEST_ID};
my $json;

my %record = (
  type => 'CNAME',
  name => 'mojo-edit-delete',
  content => 'home.thorsen.pm',
  ttl => 1,
);

if(!$id) {
  $json = $cf->add_record(\%record);

  ok $id = $json->get('/obj/rec_id'), 'add_record: /obj/rec_id';
  is $json->get('/obj/name'), "mojo-edit-delete.$args[0]", 'add_record: /obj/name';
  is $json->get('/obj/zone_name'), $args[0], 'add_record: /obj/zone_name';

  $id or BAIL_OUT "Could not add record!";
  diag $id;
}

{
  $record{id} = $id;
  $record{content} = 'thorsen.pm';
  $json = $cf->edit_record(\%record);
  is $json->get('/obj/rec_id'), $id, 'edit_record /obj/rec_id';
  is $json->get('/obj/content'), "thorsen.pm", 'edit_record /obj/content';

  $json = $cf->delete_record($id);
  is_deeply $json->data, {}, 'delete_record';
}

done_testing;
