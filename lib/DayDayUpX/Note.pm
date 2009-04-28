package DayDayUpX::Note; # make CPAN happy

use MooseX::Declare;

class DayDayUpX::Note {

    use MooseX::Types::Moose qw(Str Int);
    use Moose::Util::TypeConstraints;

    has 'text' => (
        is  => 'rw',
        isa => Str,
        required => 1,
    );
    
    enum 'NoteStatus' => qw(open closed rejected suspended);
    has 'status' => (
        is  => 'rw',
        isa => 'NoteStatus',
        default => 'open',
    );
    
    has 'time' => ( is => 'rw', isa => Int, required => 1 );
    has 'closed_time' => ( is => 'rw', isa => Int, default => 0 );
};

1;