package Mojo::Cloudflare::Record;

=head1 NAME

Mojo::Cloudflare::Record - Represent a Cloudflare DNS record

=head1 DESCRIPTION

L<Mojo::Cloudflare::Record> represents a DNS record in the
L<Mojo::Cloudflare> module.

This module inherit from L<Mojo::JSON::Pointer>.

=cut

use Mojo::Base 'Mojo::JSON::Pointer';
use Mojo::JSON::Pointer;
use Mojo::UserAgent;

require Mojo::Cloudflare;

=head1 ATTRIBUTES

=head2 content

The content of the DNS record, will depend on the the type of record being added.

=head2 name

Name of the DNS record.

=head2 priority

MX record priority.

=head2 ttl

TTL of record in seconds. 1 (default) = Automatic, otherwise, value must in
between 120 and 86400 seconds.

=head2 type

Type of the DNS record: A, CNAME, MX, TXT, SPF, AAAA, NS, SRV, or LOC.

=cut

for my $attr (qw( content name priority ttl type )) {
  has $attr => sub { shift->data->{$attr} || '' };
}

# Will be public once I know what to call the attribute
has _cf => sub { Mojo::Cloudflare->new };

sub _new_from_tx {
  my($class, $tx) = @_;
  my $err = $tx->error;
  my $json = $tx->res->json || {};

  $json->{result} //= '';
  $err ||= $json->{msg} || $json->{result} || 'Unknown error.' if $json->{result} ne 'success';

  return $err, $class->new($json->{response}{rec} || {});
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
