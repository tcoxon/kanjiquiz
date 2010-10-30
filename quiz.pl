#!/usr/bin/perl

use strict;
use warnings;

use Encode qw/encode decode/;
use Lingua::JA::Romaji qw/kanatoromaji romajitokana/;
use Term::ReadLine;

use utf8;
binmode STDOUT, ':utf8';

my $term = Term::ReadLine->new('kanjiquiz');

my @fields = (
    ['Kanji', 'kanji'],
    ['Meaning', 'meaning'],
    ["On'yomi", 'on_yomi'],
    ["Kun'yomi", 'kun_yomi'],
);

my %testing = (
    kanji => 0,
    meaning => 0,
    on_yomi => 0,
    kun_yomi => 0,
);

my %normalizers = (
    kanji => \&noop,
    meaning => \&noop,
    on_yomi => \&romaji2katakana,
    kun_yomi => \&romaji2hiragana,
);

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
    my @parts = split/-/, $r;
    $_ = eucjp2utf8(romajitokana(utf82eucjp($_), $kana)) for @parts;
    join '', @parts;
}
sub romaji2katakana { romaji2kana(shift, 'kata') }
sub romaji2hiragana { romaji2kana(shift, 'hira') }
sub kana2romaji {
    my $k = shift;
    return "" if !defined $k || $k eq "";
    eucjp2utf8(kanatoromaji(utf82eucjp($k)))
}

sub load_db {
    my $grade = shift;
    my @db;
    
    die "Not a grade number: $grade" if $grade !~ /^\d+$/;
    open my $fp, '<', "kyouiku/$grade.csv";
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
        @parts = map { my @a = split /\|/, $_; \@a } @parts;
        my ($meaning, $on_yomi, $kun_yomi) = @parts;

        push @db, {
            kanji => $kanji,
            meaning => $meaning,
            on_yomi => [map {romaji2katakana($_)} @$on_yomi],
            kun_yomi => [map {romaji2hiragana($_)} @$kun_yomi],
        };
    }
    close $fp;
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
    print "ans: $ans, length: ", length $ans, ", bytelen: ", bytelength($ans), "\n";
    $ans = $normalizer->($ans) if bytelength($ans) eq length $ans;
    print "normalized: $ans\n";
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
    my $input = $term->readline($prompt);

    print "\n" if !defined $input;
    die ":quit" if !defined $input || $input eq ":q" || $input eq ":quit";

    return $input;
}

sub test_info {
    my ($label, $row, $key) = @_;
    my $v = $row->{$key};
    my @data = ref $v ? @$v : ($v);
    my $orig_count = scalar @data;
    my $n = 1;

    while (@data) {
        my $prompt = "$label ($n/$orig_count):".(" " x (20 - length $label));
        my $ans = get_input($prompt);
        my $ans_pos;
        if ($ans_pos = check_ans($ans, \@data, $normalizers{$key})) {
            print "Correct answer! ", $data[$ans_pos-1], "\n";
            splice(@data, $ans_pos-1, 1);
            $n ++;
        } elsif ($ans eq '?') {
            print "Skipping question. Other answers were:\n";
            print "          $_\n" for @data;
            last;
        } else {
            print "Sorry, that was not a correct answer. Try again or enter ",
                "'?' to skip the question.\n";
        }
    }
}

sub main {
    print "Kanjiquiz\nEnter ':quit' (or send EOF) at any prompt to exit.\n\n";

    eval {
        my $db = load_db(1);

        for my $k (@$db) {
            for my $field (@fields) {
                show_info($field->[0], $k, $field->[1]) if !$testing{$field->[1]};
            }
            for my $field (@fields) {
                test_info($field->[0], $k, $field->[1]) if $testing{$field->[1]};
            }
            print "\n";
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
