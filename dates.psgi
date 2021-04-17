#!/usr/bin/plackup

package DatePicker::PSGI;

use strict;
use warnings;

use Plack;
use Plack::Builder;
use Plack::Request;
use Plack::App::File;
use Plack::Util;

use Data::Dumper;
use HTTP::Status qw( HTTP_NOT_FOUND HTTP_SEE_OTHER );
use YAML qw(LoadFile DumpFile);
use JSON;


my $json = JSON->new->utf8->pretty;

my $uuid_regex = qr/^\w{8,8}-(?:\w{4,4}-){3,3}\w{12,12}$/;

my $app = builder {
   mount '/' => Plack::App::File->new(file => './vote.html')->to_app;
   mount '/js/' => Plack::App::File->new(root => './js/')->to_app;
   mount '/data', builder {
       sub {
           my $env = shift;
           my $request = Plack::Request->new($env);

           my $query = $request->query_string;
           $query = substr($query, 1)
               if $query =~ m/^\?/; # begins with the question mark?

           my ($event, $user) = split( m!/!, $query, 2);
           my $event_match = $event =~ $uuid_regex;
           return [ HTTP_NOT_FOUND,
                    [ 'Content-Type' => 'text/plain' ],
                    [ 'Incorrect appointment or user specified' ] ]
               unless ($event =~ $uuid_regex and $user =~ $uuid_regex);

           return [ HTTP_NOT_FOUND,
                    [ 'Content-Type' => 'text/plain' ],
                    [ 'Unknown appointment or user specified' ] ]
               unless (-f "data/$event.yml");

           my $event_data = LoadFile("data/$event.yml");
           return [ HTTP_NOT_FOUND,
                    [ 'Content-Type' => 'text/plain' ],
                    [ 'Unknown appointment or user specified' ] ]
               unless (exists $event_data->{users}->{$user});

           if ($request->method eq 'POST') {
               my $user_dates = $event_data->{users}->{$user}->{dates};
               my $new_dates = $json->decode($request->content);
               for my $date (map { $_->{id} } $event_data->{dates}->@*) {
                   $user_dates->{$date} = ($new_dates->{$date} ? 1 : '');
               }
               DumpFile("data/$event.yml", $event_data);
           }

           my $users = $event_data->{users};
           my $rv = {
               headers => [
                   { id => 'name', text => 'Name' },
                   $event_data->{dates}->@*,
                   ],
               rows => [
                   map {
                       {
                           selectable => ($user eq $_),
                           $users->{$_}->%*
                       }
                   } sort { $users->{$a}->{name} cmp $users->{$b}->{name}
                   } keys $event_data->{users}->%*
                   ],
           };
           return [ 200,
                    [ 'Content-Type' => 'application/json' ],
                    [ $json->encode($rv) ] ];
       };
   };
};

