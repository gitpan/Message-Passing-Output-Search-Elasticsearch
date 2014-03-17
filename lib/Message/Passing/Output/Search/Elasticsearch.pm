package Message::Passing::Output::Search::Elasticsearch;
$Message::Passing::Output::Search::Elasticsearch::VERSION = '0.002';
# ABSTRACT: index messages in Elasticsearch

use Moo;
use MooX::Types::MooseLike::Base
    qw( Str ArrayRef HashRef CodeRef is_CodeRef AnyOf ConsumerOf InstanceOf );

#use Sub::Quote qw( quote_sub );
use Search::Elasticsearch;
use Search::Elasticsearch::Bulk;

with 'Message::Passing::Role::Output';



has es_params => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);


has es => (
    is      => 'ro',
    lazy    => 1,
    isa     => ConsumerOf ['Search::Elasticsearch::Role::Client'],
    builder => sub {
        my $self = shift;
        return Search::Elasticsearch->new( %{ $self->es_params } );
    },
);


has es_bulk_params => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);


has es_bulk => (
    is      => 'ro',
    lazy    => 1,
    isa     => InstanceOf ['Search::Elasticsearch::Bulk'],
    builder => sub {
        my $self = shift;
        return Search::Elasticsearch::Bulk->new( %{ $self->es_bulk_params },
            es => $self->es );
    },
);


has type => (
    is       => 'ro',
    required => 1,
    isa      => AnyOf [ Str, CodeRef ],
);


has index_name => (
    is       => 'ro',
    required => 1,
    isa      => AnyOf [ Str, CodeRef ],
);


sub consume {
    my ( $self, $data ) = @_;
    return
        unless defined $data && ref $data eq 'HASH';

    #if ( my $epochtime = delete $data->{epochtime} ) {
    #$date = DateTime->from_epoch(epoch => $epochtime);
    #}
    #$date ||= DateTime->from_epoch(epoch => time());

    my $type =
        is_CodeRef( $self->type )
        ? $self->type->($data)
        : $self->type;
    my $index_name =
        is_CodeRef( $self->index_name )
        ? $self->index_name->($data)
        : $self->index_name;

    #$self->_indexes->{$index_name} = 1;
    #    my $to_queue = {
    #        '@timestamp'   => to_ISO8601DateTimeStr($date),
    #        '@tags'        => [],
    #        '@type'        => $type,
    #        '@source_host' => delete( $data->{hostname} ) || 'none',
    #        '@message'     => exists( $data->{message} )
    #        ? delete( $data->{message} )
    #        : encode_json($data),
    #        '@fields' => $data,
    #        exists( $data->{uuid} ) ? ( id => delete( $data->{uuid} ) ) : (),
    #    };
    $self->es_bulk->create(
        {   index  => $index_name,
            type   => $type,
            source => $data,
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Message::Passing::Output::Search::Elasticsearch - index messages in Elasticsearch

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This output is intentionally kept simple to not add dependencies.
If you need a special format use a filter like
L<Message::Passing::Filter::ToLogstash> before sending messages to this
output.
The only two Elasticsearch specific fields are type and index name.

=head1 ATTRIBUTES

=head2 es_params

A hashref of L<Search::Elasticsearch/"CREATING A NEW INSTANCE"> parameters.

=head2 es

An object conforming to the L<Search::Elasticsearch::Role::Client> role. Can either be
passed directly or gets constructed from L</es_params>.

=head2 es_bulk_params

A hashref of L<Search::Elasticsearch::Bulk/"CREATING A NEW INSTANCE"> parameters.

=head2 es_bulk

A L<Search::Elasticsearch::Bulk> instance. Can either be passed directly or gets
constructed from L</es_bulk_params> in which case 'es' is set to L</es>.

=head2 type

Can be either set to a fixed string or a coderef that's called for every
message to return the type depending on the contents of the message.

=head2 index_name

Can be either set to a fixed string or a coderef that's called for every
message to return the index name depending on the contents of the message.

=head1 METHODS

=head2 consume ($msg)

Consumes a message, queuing it for consumption by Elasticsearch.
Assumes that the message is a hashref, skips silently in case it isn't.

=head1 SEE ALSO

=over

=item L<Message::Passing>

=back

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
