# NAME

Net::Twitter::Queue - Tweet from a queue of messages

# SYNOPSIS

Create a Net::Twitter::Queue passing it the tweets yaml and Twitter OAuth
information (or specify these in a config file).  Each time [tweet](#pod_tweet)
is called, the top entry in the tweets file is removed and emitted.

    # Pass information or use config.yaml
    my $twitQueue = Net::Twitter::Queue->new(
        tweets_file: mah_tweets.yaml
        consumer_key: <consumer_key>
        consumer_secret: <consumer_secret>
        access_token: <access_token>
        access_token_secret: <access_token_secret>
    );
    $twitQueue->tweet();

I use Net::Twitter::Queue to back Twitter accounts that I don't want to
handle manually.  I have directory, ~/twitter/<name> for each account
containing a config.yaml and tweets.yaml.  A cron line then invokes
Net::Twitter::Queue each day to post a tweet:

    0 8 * * * cd /home/dinomite/twitter/dailywub; perl -MNet::Twitter::Queue -e '$q = Net::Twitter::Queue->new(); $q->tweet();'
=cut

use Carp;
use Net::Twitter 3.12000;
use YAML::Any 0.70 qw(LoadFile DumpFile);

# ATTRIBUTES

- configFile

The configuration file.

    # config.yaml
    consumer_key: <consumer_key>
    consumer_secret: <consumer_secret>
    access_token: <access_token>
    access_token_secret: <access_token_secret>

Default: config.yaml

- tweetsFile

A file full of tweets

    # tweets.yaml
    - Inane location update via @FourSquare!
    - Eating a sandwich
    - Poopin'

Default: tweets.yaml; change in config.yaml

# METHODS

## tweet()

Remote the top tweet from the tweet_file and tweet it.