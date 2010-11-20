#!/usr/bin/perl

use strict;
use warnings;

use Encode qw/encode decode/;
use Lingua::JA::Romaji qw/kanatoromaji romajitokana/;
use Term::ReadLine;
use List::Util 'shuffle';

use utf8;
binmode STDOUT, ':utf8';

# static definitions that shouldn't change
my $term = Term::ReadLine->new('kanjiquiz');

my @fields = (
    ['Kanji', 'kanji'],
    ['Meaning', 'meaning'],
    ["On'yomi", 'on_yomi'],
    ["Kun'yomi", 'kun_yomi'],
);

my %normalizers = (
    kanji => \&noop,
    meaning => \&noop,
    on_yomi => \&romaji2katakana,
    kun_yomi => \&romaji2hiragana,
);

my %commands = (
    '' => \&cmd_noop,
    help => \&cmd_help,
    quit => \&cmd_quit,
    load => \&cmd_load,
    grade => \&cmd_grade,
    train => \&cmd_train,
    quiz => \&cmd_quiz,
    'shuffle-on' => \&cmd_shuffle_on,
    'shuffle-off' => \&cmd_shuffle_off,
    list => \&cmd_list,
    show => \&cmd_show,
    'problem-areas' => \&cmd_problem_areas,
);

# definitions of things commands are allowed to change
my %testing = (
    kanji => 0,
    meaning => 1,
    on_yomi => 1,
    kun_yomi => 1,
);

my ($db, $db_name);
my %kanjiIndices;
my $term_height;
my $shuffle = 0;
# quiz stats:
my ($right,$wrong) = (0,0);
my $user_data;
my ($quiz_start_at,$quiz_type);
my ($wrong_answers, $right_answers) = ('','');

# Commands:

sub cmd_noop {}

sub tally_answer {
    my ($k,$rw,$tally) = @_;
    $tally->{$k} = [0,0] if !defined $tally->{$k};
    $tally->{$k}->[$rw] ++;
}

sub tally_answers {
    my ($ks, $rw, $tally) = @_;
    for my $k (@$ks) {
        tally_answer($k, $rw, $tally) if defined $k and $k ne ""
    }
}

sub pass_rate {
    my ($wrong, $right) = @{$_[0]};
    ($right + 0.0) / ($right + $wrong) * 100.0
}

sub cmd_problem_areas {
    check_db_open();
    print "In the current database, you've had the most trouble with the ",
        "following kanji:\n\n";

    if (!-e $user_data) {
        print "No records.\n";
    } else {
        open USER_FILE, '<', $user_data or
            die "Unable to open $user_data";
        binmode USER_FILE, ':utf8';
        my %indices;
        for (grep /,$db_name,/, <USER_FILE>) {
            chomp;
            my ($time, $db, $type, $right, $wrong, $wrong_answers, $right_answers) = split/,/;
            my @wrong_answers = split /;/, $wrong_answers;
            my @right_answers = split /;/, $right_answers;
            tally_answers(\@wrong_answers, 0, \%indices);
            tally_answers(\@right_answers, 1, \%indices);
        }
        close USER_FILE;
        my @problems = keys %indices;

        # order the problem-area kanjis and remove 100% pass-rate kanjis
        @problems = sort { pass_rate($indices{$a}) <=> pass_rate($indices{$b}) }
            grep { $indices{$_}->[0] != 0 }
                @problems;

        if (@problems) {
            for (splice @problems, 0, 10) {
                printf "%s (index % 3d) :    %.0f%% pass rate\n",
                    $db->[$_]->{kanji}, int($_)+1, int pass_rate($indices{$_});
            }
        } else {
            print "None\n";
        }
    }
}

sub cmd_shuffle_on {
    $shuffle = 1;
}

sub cmd_shuffle_off {
    $shuffle = 0;
}

sub cmd_help {
    my $cmd = 'perldoc "'.__FILE__.'"';
    print "[$cmd]\n";
    system($cmd) and die "Perldoc failed with status $?";
}

sub cmd_quit {
    die ":quit";
}

sub cmd_load {
    $db = load_db(shift);
}

sub cmd_grade {
    $db = load_grade(shift);
}

sub cmd_list {
    check_db_open();

    my $i = 0;
    for my $row (@$db) {
        printf "% 3d. %s ", $i+1, $row->{kanji};
        
        ++ $i;
        print "\n" if ($i % 10 == 0);
    }
}

sub cmd_show {
    check_db_open();

    my $range = shift;
    die "A range (e.g. '1,3-5,7') must be specified for show"
        if !defined $range;

    for my $row (select_elems($range, @$db)) {
        show_info($_->[0], $row, $_->[1]) for @fields;
        print "\n";
    }
}

sub cmd_train {
    my $range = shift;
    quiz_start('train');
    eval {
        for my $k (train_set($range)) {
            show_info($_->[0], $k, $_->[1]) for @fields;

            print "\nHit enter when you're ready to be tested on this Kanji, or".
                " enter ':cancel' to cancel training.\n";
            get_input("...");
            print "\n" x $term_height;

            test_kanji($k);

            print "\nHit enter to continue with the next Kanji, or enter ':cancel'".
                " to cancel training.\n";
            get_input("...");
            print "\n" x $term_height;
        }
    };
    die if $@ && $@ !~ /^:cancel/;
    quiz_finish();
}

sub cmd_quiz {
    my $range = shift;
    quiz_start('quiz');
    eval {
        test_kanji($_) for train_set($range);
    };
    die if $@ && $@ !~ /^:cancel/;
    quiz_finish();
}

# Rest of the program: 

sub quiz_start {
    # called at the start of a quiz or train session
    ($right,$wrong) = (0,0);
    $quiz_start_at = time;
    $quiz_type = shift;
    $wrong_answers = '';
    $right_answers = '';
}

sub quiz_finish {
    # called at the end of a quiz or train session
    print "You got $right right and $wrong wrong answers. ";
    print "Congratulations! " if $wrong == 0;
    my $total = $right+$wrong;
    my $percentage;
    if ($total != 0) {
        $percentage = ($right + .0)/$total*100.0;
    } else {
        $percentage = 100.0;
    }
    print "$right/$total = $percentage%\n";

    open USER_FILE, '>>', $user_data or
        die "Couldn't open $user_data to save progress";
    binmode USER_FILE, ':utf8';
    print USER_FILE "$quiz_start_at,$db_name,$quiz_type,$right,$wrong,",
        "$wrong_answers,$right_answers\n";
    close USER_FILE;
}

sub train_set {
    # Umm... It's not one of those toy things.
    # It means "TRAINING set!"
    my $range = shift;

    check_db_open();

    my @set = select_elems($range, @$db);
    @set = shuffle(@set) if ($shuffle);
    @set;
}

sub range {
    my $first = shift;
    my $last = pop;
    return () if !defined $first;
    return $first if !defined $last;
    die "Ranges must be of whole numbers"
        if $first !~ /^\d+$/ || $last !~ /^\d+$/;

    my @res;
    if ($first < $last) {
        for (my $i = $first; $i <= $last; $i++) {
            push @res, $i;
        }
    } else {
        for (my $i = $first; $i >= $last; $i--) {
            push @res, $i;
        }
    }
    @res;
}

sub parse_range {
    my @ranges = split /,/, shift;
    map { range(split /-/, $_) } @ranges
}

sub select_elems ($@) {
    # Returns the elements of @arr indexed by the specified range
    my ($range, @arr) = @_;
    my @res;
    for my $n (parse_range($range)) {
        push @res, $arr[$n-1];
    }
    @res
}

sub test_kanji {
    my $k = shift;

    for my $field (@fields) {
        show_info($field->[0], $k, $field->[1]) if !$testing{$field->[1]};
    }
    for my $field (@fields) {
        test_info($field->[0], $k, $field->[1]) if $testing{$field->[1]};
    }
    print "\n";
}

sub check_db_open {
    die "You must first load a Kanji database with the 'grade' or 'load'".
        " commands" if !defined $db;
}

sub bytelength {
    use bytes;
    length shift;
}

sub eucjp2utf8 { decode('euc-jp', shift) }
sub utf82eucjp { encode('euc-jp', shift) }

sub noop { shift }

sub romaji2kana {
    my ($r,$kana) = @_;
    return "" if !defined $r;
    # All this craziness is to ensure kana in input is left alone
    my @parts = grep {!/^[-']$/} split /(\W+)/, $r;
    for (@parts) {
        $_ = eucjp2utf8(romajitokana(utf82eucjp($_), $kana)) if /^\w+$/
    }
    join '', @parts;
}
sub romaji2katakana { romaji2kana(shift, 'kata') }
sub romaji2hiragana { romaji2kana(shift, 'hira') }
sub kana2romaji {
    my $k = shift;
    return "" if !defined $k || $k eq "";
    eucjp2utf8(kanatoromaji(utf82eucjp($k)))
}

sub load_grade {
    my $grade = shift;
    die "Not a grade number: '$grade'" if $grade !~ /^\d+$/;
    load_db("kyouiku/$grade.csv");
}

sub load_db {
    my $fn = shift;
    my @db;
    
    open my $fp, '<', $fn or die "Couldn't load db '$fn': $!";
    binmode $fp, ':utf8';
    while (<$fp>) {
        chomp;
        s/ō/ou/g;
        s/ū/uu/g;
        s/ā/aa/g;
        s/ī/ii/g;
        s/ē/ei/g;
        my @parts = split /,/, $_;
        my $kanji = shift @parts;
        @parts = map { [split(/\|/, $_)] } @parts;
        my ($meaning, $on_yomi, $kun_yomi) = @parts;

        push @db, {
            kanji => $kanji,
            meaning => $meaning,
            on_yomi => [map {romaji2katakana($_)} @$on_yomi],
            kun_yomi => [map {romaji2hiragana($_)} @$kun_yomi],
        };
    }
    close $fp;

    $db_name = $fn;

    # populate %kanjiIndices for quickly finding indices of kanji
    %kanjiIndices = ();
    my $i = 0;
    for (@db) {
        $kanjiIndices{$_->{kanji}} = $i ++;
    }

    \@db
}

sub show_info {
    my ($label, $row, $key) = @_;
    my $data = $row->{$key};
    $data = [$data] if !ref $data;
    for (@$data) {
        next if $_ eq "";
        my $text = $_;
        print "$label:".(" " x (20 - length $label)).$_."\n";
    }
}

sub check_ans {
    my ($ans, $valid_ans, $normalizer) = @_;
    $ans = $normalizer->($ans) if bytelength($ans) eq length $ans;
    my $i = 1;
    for (@$valid_ans) {
        if ($_ eq $ans) {
            return $i;
        }
        $i++;
    }
    0
}

sub get_input {
    my $prompt = shift;
    my $input = decode('utf8', $term->readline($prompt));

    if (!defined $input) {
        print "\n";
        die ":quit";
    }
    die $input if $input =~ /^:/;

    return $input;
}

sub find_kanji {
    return $kanjiIndices{(shift)}
}

sub test_info {
    my ($label, $row, $key) = @_;
    my $v = $row->{$key};
    my @data = ref $v ? @$v : ($v);
    my $orig_count = scalar @data;
    my $n = 1;

    while (@data) {
        my $prompt = "$label ($n/$orig_count)";
        $prompt .= ':' . (' ' x (20 - length $prompt));
        my $ans = get_input($prompt);
        my $ans_pos;
        if ($ans_pos = check_ans($ans, \@data, $normalizers{$key})) {
            print "Correct answer! ", $data[$ans_pos-1], "\n";
            splice(@data, $ans_pos-1, 1);
            $n ++;
            $right ++;
            $right_answers .= find_kanji($row->{kanji}).';';
        } else {
            $wrong ++;
            $wrong_answers .= find_kanji($row->{kanji}).';';

            if ($ans eq '?' || $ans eq '？') {
                print "Skipping question. Other answers were:\n";
                print "          $_\n" for @data;
                last;
            } else {
                print "Sorry, that was not a correct answer. Try again or enter ",
                    "'?' to skip the question.\n";
            }
        }
    }
}

sub setup {
    # Calculate terminal height for hiding answers during `train`
    if (!defined $term_height) {
        if (defined $ENV{TERM_HEIGHT}) {
            # try getting the value from an environment variable
            $term_height = $ENV{TERM_HEIGHT};
        } else {
            # try getting the value from `stty` if possible
            my $stty = `stty -a`;
            if (defined $stty && $? == 0) {
                ($term_height,) = $stty =~ /rows\s+(\d+);/;
            } else {
                $term_height = 24;
                warn 'No $TERM_HEIGHT environment variable, and couldn\'t '.
                    'determine terminal height with `stty`, so falling back to'.
                    ' 24';
            }
        }
    }

    # Determine where to save user data
    $user_data = "$ENV{HOME}/.kanjiquiz_progress";
    for (@ARGV) {
        if (/^--dev$/) {
            $user_data .= '.dev';
        }
    }
}

sub main {
    setup();

    print "Kanjiquiz\n";
    print "Enter ':quit' (or send EOF) at any prompt to exit.",
        " During training or a quiz, you may also enter ':cancel' to get back",
        " to the main prompt.\n";
    print "\nThis Kanji tutor is interactive. Enter 'help' for a list of ",
        "valid commands.\n\n";

    eval {
        while (1) {
            my $input = get_input('> ');
            $input =~ s/(^\s+|\s+$)//g; # trim whitespace from ends
            my ($command, $args) = $input =~ /^(\S+)(?:\s+(.*))?$/;
            $command = "" if !defined $command;
            $args = "" if !defined $args;

            if (defined $commands{$command}) {
                eval {
                    $commands{$command}->($args);
                };
                if ($@ !~ /^:quit/) {
                    print STDERR $@, "\n";
                } elsif ($@) {
                    die
                }
            } else {
                print "Unrecognized command '$command'. Enter 'help' for a ",
                    "list of valid commands.\n";
            }
        }
    };
    print "\n";
    if ($@ =~ /^:quit/) {
        print "User quit.\n";
    } elsif ($@) {
        die
    }
}

main();

__END__

=encoding utf-8

=head1 KANJIQUIZ

Kanjiquiz - Kanji tutor and quizmaster

=head1 SYNOPSIS

    perl quiz.pl

=head1 DESCRIPTION

Kanjiquiz uses a database of kanji to present and test you on their
meanings and readings.

On starting quiz.pl, you'll be presented with a command prompt. The
following section documents the available commands.

=head2 COMMANDS

=over

=item help

Displays this documentation.

=item quit

Exits Kanjiquiz.

=item load I<file>

Replaces the current database with the kanji in the specified file.

=item grade I<grade>

Replaces the current database with the list of kanji learned in kyouiku grade I<grade>. This is the same as entering "load kyouiku/I<grade>.csv".

=item list

List every kanji in the current database, along with its index, which can be
used in arguments to other commands.

=item show I<range>

Show information on the kanji in the specified range of indices. Indices can be
found by using the C<list> command.

=item train [I<range>]

Training mode. This will go through the list of kanji one by one. For each
kanji, it will display the data for you to memorize. Once you have memorized the
data, it will clear the screen and ask you to repeat it back.

If I<range> is specified, it will only train you on the kanji with indices in
the specified range. Indices can be found by using the C<list> command.

Input for meanings must be in English.

Input for readings may be in romaji or kana, but if you enter answers in kana,
it must be in the correct kana (i.e. Katakana for On'yomi, and Hiragana for 
Kun'yomi).

=item quiz [I<range>]

Quiz mode. This will go through the list of kanji one by one and ask you to
remember meanings and readings for each one, without first showing you what
they are.

If I<range> is specified, it will only quiz you on the kanji with indices in
the specified range. Indices can be found by using the C<list> command.

Input for meanings must be in English.

Input for readings may be in romaji or kana, but if you enter answers in kana,
it must be in the correct kana (i.e. Katakana for On'yomi, and Hiragana for
Kun'yomi).

=item shuffle-on

Enables shuffling (randomized order) in quiz and training mode.

=item shuffle-off

Disables shuffling (randomized order) in quiz and training mode. Default.

=item problem-areas

Uses the statistics gathered from running quizes and training to show you the
top 10 kanji for which you've given wrong answers.

=back

=head3 RANGES

Some commands allow you to choose a set of kanji records by specifying a range. Example ranges:

=over

=item 5

=item 6,8

=item 3-8

=item 1,3-5,7

=item 8-1

=back

=head2 SPECIAL COMMANDS

The following special commands may be entered at any prompt (not just the main
prompt).

=over

=item :quit

Quits Kanjiquiz completely. Sending EOF (Ctrl-D on some systems) will have the
same effect.

=item :cancel

Entering this during a quiz or during training will cause the current training
or quiz to be canceled, leaving you at the main prompt.

=back

=head2 CUSTOMIZATION

=head3 Writing your own databases

Kanjiquiz allows you to specify your own kanji databases if you would like to
learn a particular subset of kanji that doesn't fall into one of the kyouiku
grades. These database can be loaded using the C<load> command.

The databases are UTF-8 CSV files. The columns are:

=over

=item * Kanji

=item * Meanings

=item * On'yomi

=item * Kun'yomi

=back

All the columns apart from the first allow you to specify multiple entries by
separating values with the ASCII vertical bar (C<|>) character.

Readings should be written in romaji. Where necessary, separate distinct mora /
syllables using the ASCII hyphen (C<->) character.

Inspection of the Kyouiku grade databases (kyouiku/*.csv) should aid in
understanding the format. Example rows:

    一,one,ichi|itsu,hito-tsu
    月,month|moon,gatsu|getsu,tsuki

=head1 REQUIREMENTS

This software requires the following on your machine:

=over

=item Term::ReadLine

You can get this with CPAN if it's not already installed on your computer.
Or, on Ubuntu, you can install it with:

    apt-get install libterm-readline-gnu-perl

=item UTF-8-capable terminal

Output and input to the program is in the UTF-8 character set, so you will
need a terminal capable of accepting and displaying these characters.

=item stty

To determine the height of your terminal, quiz.pl calls out to the stty
command. If C<stty> is not on your PATH, you may instead specify the height of
your terminal in the environment variable C<TERM_HEIGHT>.

=back

=head1 AUTHORS

Tom Coxon and Jacob C Kesinger.

Kyouiku database files (kyouiku/*.csv) were created using the Wikipedia
page on Kyouiku Kanji:
L<http://en.wikipedia.org/wiki/Ky%C5%8Diku_kanji>

=head1 COPYRIGHT AND LICENSE

Kanjiquiz is copyright (C) 2010, Tom Coxon. Lingua::JA::Romaji is copyright of
Jacob C Kesinger. Both are distributed under the GNU General Public License
version 2.

The Kyouiku Kanji database is licensed under the Create Commons
Attribution-ShareAlike license.

=head1 SEE ALSO

L<http://github.com/tcoxon/kanjiquiz/>
