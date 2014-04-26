package Mojo::Cloudflare;

=head1 NAME

Mojo::Cloudflare - Talk with the cloudflare API using Mojo::UserAgent

=head1 VERSION

0.02

=head1 DESCRIPTION

L<Mojo::Cloudflare> is an async client for the L<CloudFlare API|http://www.cloudflare.com/docs/client-api.html>.

=head1 SYNOPSIS

  use Mojo::Cloudflare;
  my $cf = Mojo::Cloudflare->new(
             email => 'sample@example.com',
             key => '8afbe6dea02407989af4dd4c97bb6e25',
             zone => 'example.com',
           );

  for my $record (@{ $cf->records("all")->get("/objs") }) {
    warn $record->{zone_name};
    
    $cf->edit_record({
      id => $record->{rec_id},
      type => 'CNAME',
      name => 'home',
      content => 'example.com',
      ttl => 1,
      service_mode => 0,
    });
  }

=cut

use Mojo::Base -base;
use Mojo::JSON::Pointer;
use Mojo::UserAgent;

our $VERSION = '0.02';

=head1 ATTRIBUTES

=head2 api_url

Holds the endpoint where we communicate. Default is
L<https://www.cloudflare.com/api_json.html>.

=head2 email

  $str = $self->email;
  $self = $self->email($str);

The e-mail address associated with the API key.

=head2 key

  $str = $self->key;
  $self = $self->key($str);

This is the API key made available on your Account page.

=head2 zone

  $str = $self->zone;
  $self = $self->zone($str);

The zone (domain) to act on.

=cut

has api_url => 'https://www.cloudflare.com/api_json.html';
has email => '';
has key => '';
has zone => '';
has _ua => sub { Mojo::UserAgent->new };

=head1 METHODS

=head2 add_record

  $json = $self->add_record(\%args);
  $self = $self->add_record(\%args, sub {
          my($self, $err, $json) = @_;
          # ...
        });

Used to add a new DNS record. C<$err> is true and contains a string on error,
while C<$json> is a L<Mojo::JSON::Pointer> object with the "rec" part from
the JSON on success:

  {
    "request" => { ... },
    "response" => {
      "rec" => { # <== this structure
        "obj" => {
          ...
        },
      },
    },
    "result": ...,
    "msg": ...
  };

Example usage:

  $rec_tag = $json->get("/obj/rec_tag");

Valid C<%args>:

=over 4

=item * type => {A,CNAME,MX,TXT,SPF,AAAA,NS,SRV,LOC},

Name of the DNS record.

=item * name => $str

Name of the DNS record

=item * content => $str

The content of the DNS record, will depend on the the type of record being added.

=item * ttl => $int

TTL of record in seconds. 1 (default) = Automatic, otherwise, value must in
between 120 and 86400 seconds.

=item * priority => $int

MX record priority.

=back

=cut

sub add_record {
  my($self, $args, $cb) = @_;
  my %args;

  %args = map {
    ($_, $args->{$_});
  } grep {
    defined $args->{$_};
  } qw( type name content ttl );

  $args{a} = 'rec_new';
  $args{prio} = $args->{priority} if defined $args->{priority};
  $args{ttl} ||= 1;

  return $self->_post(\%args, $cb);
}

=head2 delete_record

  $json = $self->delete_record($id);
  $self = $self->delete_record($id, sub {
          my($self, $err, $json) = @_;
          # ...
        });

Used to delete a DNS record. C<$err> is true and contains a string on error,
while C<$json> is a L<Mojo::JSON::Pointer> object on success.

=cut

sub delete_record {
  my($self, $id, $cb) = @_;

  $self->_post(
    { a => 'rec_delete', id => $id },
    $cb,
  );
}

=head2 edit_record

  $json = $self->edit_record(\%args);
  $self = $self->edit_record(\%args, sub {
          my($self, $err, $json) = @_;
          # ...
        });

Used to edit a DNS record. C<$err> is true and contains a string on error,
while C<$json> is a L<Mojo::JSON::Pointer> object on success.

See L</add_record> for more details on the response.

Valid C<%args>:

=over 4

=item * id => $str

DNS Record ID. Required argument.

=item * type => {A,CNAME,MX,TXT,SPF,AAAA,NS,SRV,LOC},

Name of the DNS record.

=item * name => $str

Name of the DNS record

=item * content => $str

The content of the DNS record, will depend on the the type of record being added.

=item * ttl => $int

TTL of record in seconds. 1 = Automatic, otherwise, value must in
between 120 and 86400 seconds.

=item * service_mode => $bool

Status of CloudFlare Proxy, 1 = orange cloud, 0 = grey cloud.

=item * priority => $int

MX record priority.

=back

=cut

sub edit_record {
  my($self, $args, $cb) = @_;
  my %args;

  %args = map {
    ($_, $args->{$_});
  } grep {
    defined $args->{$_};
  } qw( id type name content ttl );

  $args{a} = 'rec_edit';
  $args{prio} = $args->{priority} if defined $args->{priority};
  $args{service_mode} = $args->{service_mode} ? 1 : 0 if defined $args->{service_mode};

  return $self->_post(\%args, $cb);
}

=head2 records

  $json = $self->records($offset);
  $self = $self->records($offset, sub {
            my($self, $err, $json) = @_;
          });

C<$offset> is optional and defaults to "all", which will retrieve all the DNS
records instead of the limit of 180 set by CloudFlare.

=cut

sub records {
  my($self, $offset, $cb) = @_;

  if(ref $offset) {
    $cb = $offset;
    $offset = 'all';
  }

  if(!defined $offset or $offset eq 'all') {
    my $all = Mojo::JSON::Pointer->new({ count => 0, has_more => undef, objs => [] });
    return $cb ? $self->_all_records_nb($all, $cb) : $self->_all_records($all);
  }
  else {
    return $self->_post({ a => 'rec_load_all', o => $offset }, $cb);
  }
}

sub _all_records {
  my($self, $all) = @_;
  my $offset = 0;

  while(defined $offset) {
    my $json = $self->_post({ a => 'rec_load_all', o => $offset });

    $all->data->{count} += $json->get('/count');
    push @{ $all->data->{objs} }, @{ $json->get('/objs') || [] };
    $offset = $json->get('/has_more') ? $json->get('/count') : undef;
  }

  return $all;
}

sub _all_records_nb {
  my($self, $all, $cb) = @_;
  my $offset = 0;
  my $retriever;

  $retriever = sub {
    my($self, $err, $json) = @_;
    my $offset;

    return $self->$cb($err, $all) if $err;

    $offset += $json->get('/count');
    $all->data->{count} = $offset;
    push @{ $all->data->{objs} }, @{ $json->get('/objs') || [] };

    return $self->$cb('', $all) unless $json->get('/has_more');
    return $self->_post({ a => 'rec_load_all', o => $offset }, $retriever);
  };

  $self->_post({ a => 'rec_load_all' }, $retriever);
}

sub _extract {
  my($self, $tx) = @_;
  my $err = $tx->error;
  my $json = $tx->res->json || {};

  $json->{result} //= '';
  $err ||= $json->{msg} || $json->{result} || 'Unknown error.' if $json->{result} ne 'success';

  if($json->{response}) {
    return $err, Mojo::JSON::Pointer->new($json->{response}{rec} || $json->{response}{recs});
  }
  else {
    return $err, Mojo::JSON::Pointer->new({});
  }
}

sub _post {
  my($self, $data, $cb) = @_;

  $data->{a} or die "Internal error: Unknown action";
  $data->{email} ||= $self->email;
  $data->{tkn} ||= $self->key;
  $data->{z} = $self->zone if $data->{a} =~ /^rec/;

  unless($cb) {
    my $tx = $self->_ua->post($self->api_url, form => $data);
    my($err, $json) = $self->_extract($tx);

    die $err if $err;
    return $json;
  }

  Scalar::Util::weaken($self);
  $self->_ua->post(
    $self->api_url,
    form => $data,
    sub { $self->$cb($self->_extract($_[1])); },
  );

  return $self;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
