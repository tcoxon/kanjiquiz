#!/usr/bin/perl

use strict;
use warnings;

use Encode qw/encode decode/;
use Lingua::JA::Romaji qw/kanatoromaji romajitokana/;

use utf8;
binmode STDOUT, ':utf8';

sub eucjp2utf8 { decode('euc-jp', shift) }
sub utf82eucjp { encode('euc-jp', shift) }

sub romaji2kana {
    my ($r,$kana) = @_;
    my @parts = split/-/, $r;
    $_ = eucjp2utf8(romajitokana(utf82eucjp($_), $kana)) for @parts;
    join '', @parts;
}
sub romaji2katakana { romaji2kana(shift, 'kata') }
sub romaji2hiragana { romaji2kana(shift, 'hira') }

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
            on_yomi => $on_yomi,
            kun_yomi => $kun_yomi,
        };
    }
    close $fp;
    \@db
}
my $db = load_db(1);

sub printeach {
    my ($hash, $key, $label, $converter) = @_;
    for (@{$hash->{$key}}) {
        next if $_ eq "";

        my $text = $_;
        $text = $converter->($text)."\t($text)" if defined $converter;
        print "$label:\t$text\n";
    }
}

for my $k (@$db) {
    print "Kanji:\t\t", $k->{kanji}, "\n";
    printeach($k, 'meaning', 'Meaning', undef);
    printeach($k, 'on_yomi', 'On\'yomi', \&romaji2katakana);
    printeach($k, 'kun_yomi', 'Kun\'yomi', \&romaji2hiragana);
    print "\n";
}
