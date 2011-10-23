use strict;
use warnings;
package Net::Twitter::Queue;
use Moose;

=head1 NAME

Net::Twitter::Queue - Tweet from a queue of messages

=head1 SYNOPSIS

    # Pass information or use config.yaml
    my $twitQueue = Net::Twitter::Queue->new(
        tweets_file: mah_tweets.yaml
        consumer_key: <consumer_key>
        consumer_secret: <consumer_secret>
        access_token: <access_token>
        access_token_secret: <access_token_secret>
    );
    # 
    $twitQueue->tweet();

=cut

use Carp;
use Net::Twitter 3.12000;
use YAML::Any 0.70 qw(LoadFile DumpFile);

=head1 ATTRIBUTES

=over 1

=item configFile

The configuration file.

    # config.yaml
    consumer_key: <consumer_key>
    consumer_secret: <consumer_secret>
    access_token: <access_token>
    access_token_secret: <access_token_secret>

Default: config.yaml

=cut

has 'configFile' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'config.yaml',
);

has 'config' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_config'
);

=item tweetsFile

A file full of tweets

    # tweets.yaml
    - Inane location update via @FourSquare!
    - Eating a sandwich
    - Poopin'

Default: tweets.yaml; change in config.yaml

=cut

has 'tweetsFile' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_tweetsFile'
);
my $DEFAULT_TWEETS_FILE = 'tweets.yaml';

has 'tweets' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    auto_deref  => 1,
    lazy        => 1,
    builder     => '_build_tweets',
);

has 'consumer_key' => (
    is      => 'rw',
    isa     => 'Str',
    clearer     => 'clear_consumer_key',
    predicate   => 'has_consumer_key',
);

has 'consumer_secret' => (
    is      => 'rw',
    isa     => 'Str',
    clearer     => 'clear_consumer_secret',
    predicate   => 'has_consumer_secret',
);

has 'access_token' => (
    is      => 'rw',
    isa     => 'Str',
    clearer     => 'clear_access_token',
    predicate   => 'has_access_token',
);

has 'access_token_secret' => (
    is      => 'rw',
    isa     => 'Str',
    clearer     => 'clear_access_token_secret',
    predicate   => 'has_access_token_secret',
);

has 'nt' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => '_build_nt',
);

=back

=cut

sub _build_nt {
    my $self = shift;

    # If connection information wasn't set, try to read the config
    if (!$self->hasConnectionInfo) {
        # See if the config has information
        if (!exists $self->config->{consumer_key} ||
            !exists $self->config->{consumer_secret} ||
            !exists $self->config->{access_token} ||
            !exists $self->config->{access_token_secret}) {
                croak "No connection information passed or in config";
        }

        # Connection info was loaded, populate the attributes
        $self->consumer_key($self->config->{consumer_key});
        $self->consumer_secret($self->config->{consumer_secret});
        $self->access_token($self->config->{access_token});
        $self->access_token_secret($self->config->{access_token_secret});
    }
    croak "No connection information available" if (!$self->hasConnectionInfo);

    my $nt = Net::Twitter->new(
        traits  => [qw/OAuth API::REST/],
        consumer_key        => $self->consumer_key,
        consumer_secret     => $self->consumer_secret,
        access_token        => $self->access_token,
        access_token_secret => $self->access_token_secret,
    );

    return $nt;
}

sub _build_config {
    my $self = shift;

    my $yaml = LoadFile($self->configFile);
    return $yaml;
}

sub _build_tweetsFile {
    my $self = shift;

    my $file = $DEFAULT_TWEETS_FILE;
    $file = $self->config->{tweets_file} if (exists $self->config->{tweets_file});

    return $file ;
}

sub _build_tweets {
    my $self = shift;

    my $tweets = LoadFile($self->tweetsFile);
    return $tweets;
}

sub hasConnectionInfo {
    my $self = shift;
    return $self->has_consumer_key &&
           $self->has_consumer_secret &&
           $self->has_access_token &&
           $self->has_access_token_secret;
}

=head1 METHODS

=head2 tweet()

Remote the top tweet from the tweet_file and tweet it.

=cut

sub tweet {
    my $self = shift;

    my $tweet = shift @{$self->tweets};
    my $result = $self->nt->update($tweet);

    if ($result) {
        DumpFile($self->tweetsFile, \@{$self->tweets});
    } else {
        carp "Tweeting didn't go well...";
    }
}

1;
