#!/usr/bin/plackup

package DatePicker::PSGI;

use 5.24.0;

use strict;
use warnings;

use Plack;
use Plack::Builder;
use Plack::Request;
use Plack::App::File;
use Plack::App::Path::Router;
use Plack::Middleware::Conditional;
use Plack::Util;

use Data::Dumper;
use Data::UUID;
use HTTP::Status qw( HTTP_OK HTTP_CREATED
    HTTP_SEE_OTHER
    HTTP_BAD_REQUEST HTTP_FORBIDDEN HTTP_NOT_FOUND
    HTTP_NOT_IMPLEMENTED );
use JSON;
use List::Util qw( any notall );
use Path::Router;
use Scalar::Util qw( reftype );
use YAML qw(LoadFile DumpFile);


my $json = JSON->new->utf8->pretty;
my $uuids = Data::UUID->new;

my $uuid_regex = qr/^\w{8,8}-(?:\w{4,4}-){3,3}\w{12,12}$/;


sub compose_resource {
    my ($event, $event_data, %args) = @_;
    my $editor = $args{editor};

    my $dates = [
        map {
            {
                key  => $_->{id},
                date => $_->{date},
                time => $_->{time}
            }
        } $event_data->{dates}->@*
        ];
    my $idx = 1;
    my $users = $event_data->{users} // {};
    my $editingOrganizer = $users->{$editor}->{organizer};
    my %sec_users = (
        map { my $i = $idx++;
              $_ => ($_ eq $editor or $editingOrganizer)
                  ? $_ : "a$i" }
        sort keys $users->%*
        );

    my $attendees = [
        map {
            {
                key       => $sec_users{$_},
                name      => $users->{$_}->{name},
                state     => ($_ eq $editor) ? 'editing' : 'presenting',
                organizer => $users->{$_}->{organizer} ? \1 : \0
            }
        } sort keys $users->%*
        ];

    my $attendance = {
        map {
            my $user_dates = $users->{$_}->{dates};
            $sec_users{$_} => {
                map { $_ => $user_dates->{$_} ? \1 : \0 }
                map { $_->{id} }
                $event_data->{dates}->@*
            }
        } sort keys $users->%*
    };

    return {
        event => $event,
        dates => $dates,
        attendees => $attendees,
        selections => $attendance
    };
}

sub verify_method {
    my ($request, $method) = @_;

    return [ HTTP_OK, [], [] ] if $request->method eq 'OPTIONS';
    return [ HTTP_NOT_IMPLEMENTED,
             [ 'Content-Type' => 'application/json' ],
             [ '{ "error": true, ',
               qq|"message": "Endpoint expects $method requests only" }| ] ]
        unless $request->method eq $method;

    return;
}

sub verify_event {
    my ($event) = shift;

    return [ HTTP_NOT_FOUND,
             [ 'Content-Type' => 'application/json' ],
             [ qq| "error": true; "message": "Incorrect appointment specified: $event" }| ] ]
        unless ($event =~ m/$uuid_regex/);

    return [ HTTP_NOT_FOUND,
             [ 'Content-Type' => 'application/json' ],
             [ '{ "error": true, ',
               '"message": "Unknown appointment or user specified" }' ] ]
        unless (-f "data/$event.yml");

    return;
}

sub verify_user {
    my ($event_data, $user) = @_;

    if ($user and $user !~ $uuid_regex) {
        return
            [ HTTP_NOT_FOUND,
              [ 'Content-Type' => 'application/json' ],
              [ '{ "error": true, "message": "Incorrect appointment specified" }' ]
            ];
    }

    if (not $event_data->{users}->{$user}) {
        return
            [ HTTP_NOT_FOUND,
              [ 'Content-Type' => 'application/json' ],
              [ '{ "error": true, "message": "Incorrect appointment specified" }' ]
            ];
    }

    return;
}

sub organizer_uuid {
    my $event_data = shift;
    my $users      = $event_data->{users};
    for my $user (keys $users->%*) {
        if ($users->{$user}->{organizer}) {
            return $user;
        }
    }
    return '';
}

my $router = Path::Router->new();

$router->add_route(
    '/' => (
        target => sub {
            my $request = shift;

            if (my $response = verify_method($request, 'POST')) {
                return $response;
            }

            return [ HTTP_BAD_REQUEST,
                     [ 'Content-Type' => 'application/json' ],
                     [ '{ "error": true, ',
                       '"message": "Endpoint expects application/json content" }'
                     ] ]
                unless $request->headers->content_type eq 'application/json';

            my $content = $json->decode($request->content);
            my $attendees = $content->{attendees};
            return [ HTTP_BAD_REQUEST,
                     [ 'Content-Type' => 'application/json' ],
                     [ '{ "error": true, ',
                       '"message": "At least one attendee expected" }'
                     ] ]
                unless ($attendees
                        and reftype $attendees
                        and reftype $attendees eq 'ARRAY'
                        and scalar($attendees->@*) > 0);

            return [ HTTP_BAD_REQUEST,
                     [ 'Content-Type' => 'application/json' ],
                     [ '{ "error": true, ',
                       '"message": "At most 50 attendees expected" }'
                     ] ]
                if (scalar($attendees->@*) > 50);

            return [ HTTP_BAD_REQUEST,
                     [ 'Content-Type' => 'application/json' ],
                     [ '{ "error": true, ',
                       '"message": "All attendees should have a non-empty \'name\' field " }'
                     ] ]
                if (notall { defined && length  }
                    map { $_->{name} }
                    $attendees->@*);

            my $dates = $content->{dates} // [];
            return [ HTTP_BAD_REQUEST,
                     [ 'Content-Type' => 'application/json' ],
                     [ '{ "error": true, ',
                       '"message": "All dates should have a non-empty \'date\' field " }'
                     ] ]
                if (notall { defined && length  }
                    map { $_->{date} }
                    $dates->@*);

            my $id = 0;
            my $first_attendee = shift $attendees->@*;
            my $organizer_data = {
                name      => $first_attendee->{name},
                organizer => 'yes'
            };
            my $organizer = lc($uuids->create_str());
            my $event_data = {
                users => {
                    $organizer => $organizer_data,
                    map {
                        lc($uuids->create_str()) => {
                            name => $_->{name},
                        }
                    } $attendees->@*
                },
                dates => [
                    map {
                        {
                            id   => 'd' . $id++,
                            date => $_->{date},
                        }
                    } $dates->@*
                    ]
            };

            my $event = lc($uuids->create_str());
            DumpFile("data/$event.yml", $event_data);

            return [ HTTP_CREATED,
                     [ 'Location' => "/data/$event",
                       'Content-Type' => 'application/json; charset=UTF-8' ],
                     [ $json->encode(
                           compose_resource($event, $event_data,
                                            editor => $organizer)
                       ) ] ];
        }
    ));

$router->add_route(
    '/:event' => (
        target => sub {
            my $request = shift;
            my $event = shift;
            my $editor = $request->query_parameters->get('editor');

            if (my $fail = verify_event($event, $editor)) {
                return $fail;
            }

            my $event_data = LoadFile("data/$event.yml");
            if (my $fail = verify_user($event_data, $editor)) {
                return $fail;
            }

            if ($request->method eq 'PATCH') {
                return [ HTTP_BAD_REQUEST,
                         [ 'Content-Type' => 'application/json' ],
                         [ '{ "error": true, ',
                           '"message": "Incorrect or missing content type ',
                           '(application/json expected)" }' ] ]
                    unless $request->headers->content_type eq 'application/json';

                my $content = $json->decode($request->content);
                my $new_dates = $content->{selections};

                # update date selections
                $event_data->{users}->{$editor}->{dates} = {
                    map { $_ => $new_dates->{$_} ? 1 : '' }
                    map { $_->{id} }
                    $event_data->{dates}->@*
                };
                DumpFile("data/$event.yml", $event_data);
            }

            return [
                HTTP_OK,
                [ 'Content-Type' => 'application/json' ],
                [ $json->encode(
                      compose_resource($event, $event_data, editor => $editor)
                      )  ] ];
        }));

$router->add_route(
    '/:event/attendees/' => (
        target => sub {
            my $request = shift;
            my $event   = shift;
            my $editor = $request->query_parameters->get('editor');

            if (my $response = verify_method($request, 'POST')) {
                return $response;
            }

            if (my $fail = verify_event($event, $editor)) {
                return $fail;
            }

            my $event_data = LoadFile("data/$event.yml");
            if (my $fail = verify_user($event_data, $editor)) {
                return $fail;
            }
            if ($editor ne organizer_uuid($event_data)) {
                return [ HTTP_FORBIDDEN, [], [] ];
            }

            my $content = $json->decode($request->content);
            my $attendee_uuid = lc($uuids->create_str());
            $event_data->{users}->{$attendee_uuid} = {
                name      => $content->{name},
            };
            DumpFile("data/$event.yml", $event_data);

            return [
                HTTP_OK,
                [ 'Content-Type' => 'application/json; charset=UTF-8' ],
                [ $json->encode({
                    key       => $attendee_uuid,
                    name      => $content->{name},
                    state     => 'presenting',
                    organizer => \0
                                })  ] ];
        }));

$router->add_route(
    '/:event/dates/' => (
        target => sub {
            my $request = shift;
            my $event   = shift;
            my $editor = $request->query_parameters->get('editor');

            if (my $response = verify_method($request, 'POST')) {
                return $response;
            }
            if (my $fail = verify_event($event, $editor)) {
                return $fail;
            }

            my $event_data = LoadFile("data/$event.yml");
            if (my $fail = verify_user($event_data, $editor)) {
                return $fail;
            }
            if ($editor ne organizer_uuid($event_data)) {
                return [ HTTP_FORBIDDEN, [], [] ];
            }

            my $content = $json->decode($request->content);
            my $date_uuid = lc($uuids->create_str());
            my $date = {
                id    => $date_uuid,
                date  => $content->{date},
                time  => $content->{time}
            };
            push $event_data->{dates}->@*, $date;
            DumpFile("data/$event.yml", $event_data);

            return [
                HTTP_OK,
                [ 'Content-Type' => 'application/json; charset=UTF-8' ],
                [ $json->encode($date)  ] ];
        }));


my $builder = Plack::Builder->new();
if ($ENV{PLACK_ENV} eq 'development') {
    $builder->add_middleware('CrossOrigin', origins => '*', max_age => 60*60*24*30);
}
$builder->mount('/data/' => Plack::App::Path::Router->new(router => $router)->to_app);
$builder->mount( '/js/' => Plack::App::File->new(root => './ui/dist/js/')->to_app);
$builder->mount( '/css/' => Plack::App::File->new(root => './ui/dist/css/')->to_app);
$builder->mount( '/favicon.ico' => Plack::App::File->new(file => './ui/dist/favicon.ico')->to_app);
$builder->mount( '/' => Plack::App::File->new(file => './ui/dist/index.html')->to_app);

my $app = $builder->to_app;
