package DayDayUp::Notes;

use strict;
use warnings;

our $VERSION = '0.05';

use base 'Mojolicious::Controller';

use Data::Dumper;

use vars qw/%levels %status/;
%levels = (
    99 => 'A-1',
    98 => 'A-2',
    97 => 'A-3',
    66 => 'B-1',
    65 => 'B-2',
    64 => 'B-3',
    33 => 'C-1',
    32 => 'C-2',
    31 => 'C-3',
);
%status = (
    0  => 'closed',
    1  => 'suspended',
    2  => 'open',
);

sub index {
    my ($self, $c) = @_;
    
    my $config = $c->config;
    my $dbh = $c->dbh;
    
    my $notes = $self->_get_notes( $c );
    $c->view(template => 'notes/index.html', notes => $notes, levels => \%levels);
}

sub add {
    my ( $self, $c ) = @_;
    
    my $stash = {
        template => 'notes/add.html',
        levels   => \%levels,
    };
    unless ( $c->req->method eq 'POST' ) {
        return $c->view( $stash );
    }
    
    my $config = $c->config;
    my $dbh = $c->dbh;
    my $params = $c->req->params->to_hash;
    
    my $notes = $params->{notes};
    my $level = $params->{level};
    my $sql = q~INSERT INTO notes ( note, level, status, time ) VALUES ( ?, ?, ?, ? )~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $notes, $level, 2, time() );
    
    $c->view(template => 'redirect.html', url => '/notes/');
}

sub _get_notes {
    my ( $self, $c ) = @_;
    
    my $notes;
    
    my $dbh = $c->dbh;
    
    # open
    my $sql = q~SELECT * FROM notes WHERE status = 2~; 
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    $notes->{open} = $sth->fetchall_arrayref({});
    
    # suspended
    $sql = q~SELECT * FROM notes WHERE status = 1~; 
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $notes->{suspended} = $sth->fetchall_arrayref({});
    
    # closed
    $sql = q~SELECT * FROM notes WHERE status = 0 ORDER BY closed_time DESC LIMIT 5~; 
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $notes->{closed} = $sth->fetchall_arrayref({});
    
    return $notes;
}

sub edit {
    my ( $self, $c ) = @_;
    
    my $captures = $c->match->captures;
    my $id = $captures->{id};
    
    my $dbh = $c->dbh;
    
    # get the note
    my $sql = q~SELECT * FROM notes WHERE note_id = ?~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $id );
    my $note = $sth->fetchrow_hashref;
    
    my $stash = {
        template => 'notes/add.html',
        levels   => \%levels,
    };
    unless ( $c->req->method eq 'POST' ) {
    	# pre-fulfill
    	$stash->{fif} = {
    		level => $note->{level},
    		notes => $note->{note},
    	};
        return $c->view( $stash );
    }
    
    my $params = $c->req->params->to_hash;
    
    my $notes = $params->{notes};
    my $level = $params->{level};
    $sql = q~UPDATE notes SET note = ?, level = ? WHERE note_id = ?~;
    $sth = $dbh->prepare($sql);
    $sth->execute( $notes, $level, $id );
    
    $c->view(template => 'redirect.html', url => '/notes/');
}

sub delete {
    my ( $self, $c ) = @_;
    
    my $captures = $c->match->captures;
    my $id = $captures->{id};
    
    my $dbh = $c->dbh;
    my $sql = q~DELETE FROM notes WHERE note_id = ?~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $id );
    
    $c->view(template => 'redirect.html', url => '/notes/');
}

sub update {
	my ( $self, $c ) = @_;
	
	my $captures = $c->match->captures;
    my $id = $captures->{id};
    
    my $dbh = $c->dbh;
    my $params = $c->req->params->to_hash;
    
    my $status = $params->{status};
    my $st_val = 2;
    foreach my $key ( keys %status ) {
    	if ( $status{ $key } eq $status ) {
    		$st_val = $key;
    		last;
    	}
    }
    
    if ( $status eq 'closed' ) {
    	my $sql = q~UPDATE notes SET status = ?, closed_time = ? WHERE note_id = ?~;
		my $sth = $dbh->prepare($sql);
		$sth->execute( $st_val, time(), $id );
    } else {
		my $sql = q~UPDATE notes SET status = ? WHERE note_id = ?~;
		my $sth = $dbh->prepare($sql);
		$sth->execute( $st_val, $id );
    }
    
    $c->view(template => 'redirect.html', url => '/notes/');
}

sub closed {
	my ( $self, $c ) = @_;
	
	my $dbh = $c->dbh;
	
	my $sql = q~SELECT * FROM notes WHERE status = 0 ORDER BY time DESC~; 
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my $closed = $sth->fetchall_arrayref({});
    
    $c->view(
		template => 'notes/index.html',
		notes => { closed => $closed },
		is_in_closed_page => 1,
		levels => \%levels
	);
}

1;
__END__

=head1 NAME

DayDayUp::Notes - Mojolicious::Controller, /notes/

=head1 URL

	/notes/
	/notes/add
	/notes/$id/edit
	/notes/$id/delete
	/notes/$id/update
	/notes/closed

=head1 AUTHOR

Fayland Lam < fayland at gmail dot com >

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut