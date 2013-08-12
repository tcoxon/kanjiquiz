#!/usr/bin/perl
use strict;
use warnings;

sub search_kanji ($) {
    my $ch = shift;
    for my $csv (glob 'kyouiku/*.csv') {
        open CSV, '<:encoding(UTF-8)', $csv or die "unable to open $csv";

        for my $row (<CSV>) {
            chomp $row;
            if ($row =~ /^$ch/) {
                return $row;
            }
        }

        close CSV;
    }
    return undef;
}

binmode STDOUT, ':utf8';
my $fname = 'lesson8.txt';

open LESSON, '<:encoding(UTF-8)', $fname
    or die "unable to open $fname";

for my $line (<LESSON>) {
    chomp $line;
    for my $ch (split//,$line) {
        if ($ch =~ /^\s+$/) { next; }
        my $row = search_kanji($ch);
        if (defined $row) {
            print "$row\n";
        } else {
            print STDERR "Couldn't find this kanji in my DB: $ch\n";
        }
    }
}

close LESSON;

