package DayDayUp::Context;

use Moose;

our $VERSION = '0.03';

extends 'Mojolicious::Context';

use YAML qw/LoadFile/;
use DBI;

has 'config' => (
    is   => 'ro',
    isa  => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $home = $self->app->home;
        my $app  = $home->app_class;
        my $file = $home->rel_file( lc($app) . '.yml' );
        unless ( -e $file ) {
            warn "Can't find config with $file\n";
            return {};
        }
        my $config = YAML::LoadFile($file);
        
        # load _local.yml
        my $file_local = $home->rel_file( lc($app) . '_local.yml' );
        if ( -e $file_local ) {
        	my $local = YAML::LoadFile($file_local);
        	$config = { %$config, %$local };
        }
        
        return $config;
    }
);

has 'dbh' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $home = $self->app->home;
        my $app  = $home->app_class;
        my $db_file = $home->rel_file( lc($app) . '.db' );
        
        # custom
        if ( exists $self->config->{db_file} ) {
        	my $db_file2 = $home->rel_file( $self->config->{db_file} );
        	if ( -e $db_file2 ) {
        		$db_file = $db_file2;
        	} else {
        		warn "$db_file2 is not found\n";
        	}
        }
        
        return DBI->connect("dbi:SQLite:dbname=$db_file", '', '', {RaiseError => 1})
            or die $DBI::err;
    }
);

1;
__END__

=head1 NAME

DayDayUp::Context - extends Mojolicious::Context

=head1 Extra Methods

=head2 config

	$c->config

it's a HashRef from YAML::LoadFile daydayup.yml and daydayup_local.yml if -e

=head2 dbh

L<DBI> with L<DBD::SQLite> with daydayup.db

=head1 AUTHOR

Fayland Lam < fayland at gmail dot com >

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
