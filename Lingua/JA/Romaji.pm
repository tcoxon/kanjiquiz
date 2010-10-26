# Jacob C. Kesinger <kesinger@math.ttu.edu>
# This is a derived work of Jim Breen's XJDIC, and as such is licensed under
# the GNU General Public License, a copy of which was distributed with perl.
package Lingua::JA::Romaji;

use 5.006;
use strict;
use warnings;
use utf8;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::JA::Romaji ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	&romajitokana &kanatoromaji %hiragana %katakana
) ] );

our @EXPORT_OK = (	qw( &kanatoromaji %hiragana %katakana ));

our @EXPORT = qw(
	&romajitokana
);
our $VERSION = '0.03';


# Preloaded methods go here.

#romajitokana ( romaji, kanatype)
#kanatype == ``hira'' or ``kana''.  
sub romajitokana {
    #let's ignore case
    my $romaji = lc $_[0];
    my $kanatype;
    return unless $romaji;
    if((defined $_[1]) && ($_[1] =~ m/kata/i)) {
        $kanatype = "kata";
    } else {
        $kanatype = "hira";
    }
    #handle goofy stuff with solitary and doubled n
    $romaji =~ s/[nm]([nm])/q$1/gi;
    $romaji =~ s/n\'/q/gi;
    $romaji =~ s/n$/q/gi;
    #handle regular stuff with singular n.  Is first regex necessary?
    $romaji =~ s/[nm]([bcdfghjkmnprstvz])/q$1/gi;
    #handle double consonants, perhaps ineffectually
    if ($romaji =~ m/([bcdfghjkmnprstvz])\1/i){
        $romaji=~ s/([bcdfghjkmnprstvz])$1/\*$1/gi;
    }
    my @roma = split(//,$romaji);
    my $curst = $roma[0];
    my $i=0;
    my $next = " ";
    my $output = "";
    while ((defined $next)&&($roma[$i] =~ m/[a-z\-\*]/i)) {
        $next = $roma[$i+1];
        unless ($next){
            if ($Lingua::JA::Romaji::roma{$curst}->{$kanatype}) {
                $output.=$Lingua::JA::Romaji::roma{$curst}->{$kanatype};
                $curst = "";
            }
        }
        next unless $next;
        unless ($Lingua::JA::Romaji::roma{$curst . $next}) {
            #we've gone too far, so print out what we've got, if anything
            if ($Lingua::JA::Romaji::roma{$curst}->{$kanatype}) {
                $output.=$Lingua::JA::Romaji::roma{$curst}->{$kanatype};
                $curst = "";

            } 
        } else {
            #if we're here, then curst.next is valid...
            unless ($roma[$i+2]){
                #...and there's nothing else
                $output.=$Lingua::JA::Romaji::roma{$curst . $next}->{$kanatype};
                $curst ="";
                $next = "";
            }
        } 
        $i++;
        $curst = $curst . $next;
    }
    return $output;
}

#kanatoromaji(kana)
sub kanatoromaji {
    my $kana = $_[0];
    my $rawb = unpack("H32", $kana);
#    print "$rawb\n";
    my $scratchkana = $kana;
    my $hirabegin = chr(0xA4);
    my $katabegin = chr(0xA5);
    my @skb = split(//,$scratchkana);
    my $newroma="";
    my $kanatype;
    if ($skb[0] eq $katabegin) {
        $kanatype = 1;
    } else {
        $kanatype = 0;
    }
    while (my $thisbyte = shift @skb) {
        if (($thisbyte eq $hirabegin) || ($thisbyte eq $katabegin)) {
            my $nextbyte = shift @skb;
            if ($Lingua::JA::Romaji::allkana{$thisbyte . $nextbyte}) {
                    $newroma .=  $Lingua::JA::Romaji::allkana{$thisbyte . $nextbyte};
            } else {
                $newroma .= $thisbyte . $nextbyte;
            }
        } else {
            $newroma .= $thisbyte;
        }
    }

    $newroma =~ s/\'$//;
    $newroma =~ s/n\'([^aeiouy])/n$1/gi;
    $newroma =~ s/\*(.)/$1$1/g;
    $newroma =~ s/ixy(.)/$1/ig;
    $newroma =~ s/ix(.)/y$1/ig;
    $newroma =~ s/ux(.)/$1/ig;
    if ($kanatype) {
        return uc $newroma;
    }
    return $newroma;
}

%Lingua::JA::Romaji::hiragana = (
               '¡¦' => '.',
               '¡¼' => '-',
               '¤­¤ã' => 'kya',
               '¤­¤å' => 'kyu',
               '¤¸¤§' => 'jye',
               '¤­¤ç' => 'kyo',
               '¤Ç¤ã' => 'dya',
               '¤Ç¤å' => 'dyu',
               '¤Ò¤§' => 'hye',
               '¤Ç¤ç' => 'dyo',
               '¤Ô¤ã' => 'pya',
               '¤Ô¤å' => 'pyu',
               '¤ß¤§' => 'mye',
               '¤Ô¤ç' => 'pyo',
               '¤Â¤ã' => 'dja',
               '¤Â¤å' => 'dju',
               '¤Â¤ç' => 'djo',
               '¤®¤§' => 'gye',
               '¤Õ¤¡' => 'fa',
               '¤Õ¤£' => 'fi',
               '¤Õ¤§' => 'fye',
               '¤Õ¤©' => 'fo',
               '¤¸¤ã' => 'jya',
               '¤¸¤å' => 'jyu',
               '¤¸¤ç' => 'jyo',
               '¤¡' => 'xa',
               '¤¢' => 'a',
               '¤£' => 'xi',
               '¤¤' => 'i',
               '¤¥' => 'xu',
               '¤Ò¤ã' => 'hya',
               '¤¦' => 'u',
               '¤§' => 'xe',
               '¤Ò¤å' => 'hyu',
               '¤¨' => 'ye',
               '¤©' => 'xo',
               '¤ª' => 'o',
               '¤Ò¤ç' => 'hyo',
               '¤«' => 'ka',
               '¤¬' => 'ga',
               '¤­' => 'ki',
               '¤ß¤ã' => 'mya',
               '¤®' => 'gi',
               '¤¯' => 'ku',
               '¤ß¤å' => 'myu',
               '¤°' => 'gu',
               '¤ê¤§' => 'rye',
               '¤±' => 'ke',
               '¤ß¤ç' => 'myo',
               '¤²' => 'ge',
               '¤Ë¤§' => 'nye',
               '¤³' => 'ko',
               '¤´' => 'go',
               '¤µ' => 'sa',
               '¤¶' => 'za',
               '¤Ã¤Á' => 'tchi',
               '¤·' => 'syi',
               '¤Ã¤Á¤§' => 'tche',
               '¤¸' => 'jyi',
               '¤®¤ã' => 'gya',
               '¤¹' => 'su',
               '¤º' => 'zu',
               '¤®¤å' => 'gyu',
               '¤»' => 'se',
               '¤®¤ç' => 'gyo',
               '¤¼' => 'ze',
               '¤½' => 'so',
               '¤¾' => 'zo',
               '¤¿' => 'ta',
               '¤À' => 'da',
               '¤Á' => 'tyi',
               '¤Â' => 'dji',
               '¤Ã' => 't-',
               '¤Ä' => 'tu',
               '¤Å' => 'dzu',
               '¤Æ' => 'te',
               '¤Ç' => 'de',
               '¤È' => 'to',
               '¤É' => 'do',
               '¤Ê' => 'na',
               '¤Ë' => 'ni',
               '¤Ó¤§' => 'bye',
               '¤Ì' => 'nu',
               '¤Í' => 'ne',
               '¤Î' => 'no',
               '¤Ï' => 'ha',
               '¤Õ¤ã' => 'fya',
               '¤Ð' => 'ba',
               '¤Ñ' => 'pa',
               '¤Õ¤å' => 'fyu',
               '¤Ò' => 'hi',
               '¤Ó' => 'bi',
               '¤Õ¤ç' => 'fyo',
               '¤Á¤§' => 'tye',
               '¤Ô' => 'pi',
               '¤Õ' => 'hu',
               '¤Ö' => 'bu',
               '¤×' => 'pu',
               '¤Ø' => 'he',
               '¤Ù' => 'be',
               '¤Ú' => 'pe',
               '¤Û' => 'ho',
               '¤Ü' => 'bo',
               '¤Ý' => 'po',
               '¤Þ' => 'ma',
               '¤ß' => 'mi',
               '¤à' => 'mu',
               '¤á' => 'me',
               '¤â' => 'mo',
               '¤ã' => 'xya',
               '¤ä' => 'ya',
               '¤å' => 'xyu',
               '¤æ' => 'yu',
               '¤ç' => 'xyo',
               '¤è' => 'yo',
               '¤é' => 'ra',
               '¤É¤¥' => 'du',
               '¤ê' => 'ri',
               '¤ë' => 'ru',
               '¤ì' => 're',
               '¤í' => 'ro',
               '¤ê¤ã' => 'rya',
               '¤î' => 'xwa',
               '¤ï' => 'wa',
               '¤ê¤å' => 'ryu',
               '¤Ë¤ã' => 'nya',
               '¤ð' => 'wi',
               '¤ñ' => 'we',
               '¤ê¤ç' => 'ryo',
               '¤Ë¤å' => 'nyu',
               '¤ò' => 'wo',
               '¤ó' => 'q',
               '¤Ã¤Á¤ã' => 'tcha',
               '¤Ë¤ç' => 'nyo',
               '¤·¤§' => 'sye',
               '¤Ã¤Á¤å' => 'tchu',
               '¤Ä¤¡' => 'tsa',
               '¤Ã¤Á¤ç' => 'tcho',
               '¤Ä¤§' => 'tse',
               '¤Ä¤©' => 'tso',
               '¤Ó¤ã' => 'bya',
               '¤Ó¤å' => 'byu',
               '¤Ó¤ç' => 'byo',
               '¤Á¤ã' => 'tya',
               '¤Á¤å' => 'tyu',
               '¤Á¤ç' => 'tyo',
               '¤­¤§' => 'kye',
               '¤Ç¤£' => 'di',
               '¤Ç¤§' => 'dye',
               '¤Ô¤§' => 'pye',
               '¤·¤ã' => 'sya',
               '¤·¤å' => 'syu',
               '¤Â¤§' => 'dje',
               '¤·¤ç' => 'syo'
             );
%Lingua::JA::Romaji::katakana = (
               '¥­¥å' => 'kyu',
               '¥¸¥§' => 'jye',
               '¥­¥ç' => 'kyo',
               '¡¦' => '.',
               '¥Ç¥ã' => 'dya',
               '¥Ç¥å' => 'dyu',
               '¥Ò¥§' => 'hye',
               '¥Ç¥ç' => 'dyo',
               '¥Ô¥ã' => 'pya',
               '¥Ô¥å' => 'pyu',
               '¥ß¥§' => 'mye',
               '¡¼' => '-',
               '¥Ô¥ç' => 'pyo',
               '¥Â¥ã' => 'dja',
               '¥Â¥å' => 'dju',
               '¥Â¥ç' => 'djo',
               '¥®¥§' => 'gye',
               '¥ô¥¡' => 'va',
               '¥ô¥£' => 'vi',
               '¥Õ¥¡' => 'fa',
               '¥Õ¥£' => 'fi',
               '¥ô¥§' => 've',
               '¥ô¥©' => 'vo',
               '¥Õ¥§' => 'fye',
               '¥Õ¥©' => 'fo',
               '¥¸¥ã' => 'jya',
               '¥¸¥å' => 'jyu',
               '¥¸¥ç' => 'jyo',
               '¥Ã¥Á¥§' => 'tche',
               '¥Ò¥ã' => 'hya',
               '¥Ò¥å' => 'hyu',
               '¥Ò¥ç' => 'hyo',
               '¥ß¥ã' => 'mya',
               '¥ß¥å' => 'myu',
               '¥ê¥§' => 'rye',
               '¥ß¥ç' => 'myo',
               '¥Ë¥§' => 'nye',
               '¥Ã¥Á' => 'tchi',
               '¥®¥ã' => 'gya',
               '¥®¥å' => 'gyu',
               '¥®¥ç' => 'gyo',
               '¥Ó¥§' => 'bye',
               '¥Õ¥ã' => 'fya',
               '¥Õ¥å' => 'fyu',
               '¥Õ¥ç' => 'fyo',
               '¥Á¥§' => 'tye',
               '¥Ã¥Á¥ã' => 'tcha',
               '¥¡' => 'xa',
               '¥Ã¥Á¥å' => 'tchu',
               '¥¢' => 'a',
               '¥£' => 'xi',
               '¥Ã¥Á¥ç' => 'tcho',
               '¥¤' => 'i',
               '¥¥' => 'xu',
               '¥¦' => 'u',
               '¥§' => 'xe',
               '¥¨' => 'ye',
               '¥©' => 'xo',
               '¥ª' => 'o',
               '¥«' => 'ka',
               '¥¬' => 'ga',
               '¥­' => 'ki',
               '¥®' => 'gi',
               '¥¯' => 'ku',
               '¥É¥¥' => 'du',
               '¥°' => 'gu',
               '¥±' => 'ke',
               '¥²' => 'ge',
               '¥ê¥ã' => 'rya',
               '¥³' => 'ko',
               '¥´' => 'go',
               '¥ê¥å' => 'ryu',
               '¥µ' => 'sa',
               '¥Ë¥ã' => 'nya',
               '¥¶' => 'za',
               '¥ê¥ç' => 'ryo',
               '¥·' => 'syi',
               '¥Ë¥å' => 'nyu',
               '¥¸' => 'jyi',
               '¥¹' => 'su',
               '¥Ë¥ç' => 'nyo',
               '¥º' => 'zu',
               '¥·¥§' => 'sye',
               '¥»' => 'se',
               '¥Ä¥¡' => 'tsa',
               '¥¼' => 'ze',
               '¥½' => 'so',
               '¥¾' => 'zo',
               '¥¿' => 'ta',
               '¥À' => 'da',
               '¥Á' => 'tyi',
               '¥Ä¥§' => 'tse',
               '¥Â' => 'dji',
               '¥Ã' => 't-',
               '¥Ä¥©' => 'tso',
               '¥Ä' => 'tu',
               '¥Å' => 'dzu',
               '¥Æ' => 'te',
               '¥Ç' => 'de',
               '¥È' => 'to',
               '¥É' => 'do',
               '¥Ê' => 'na',
               '¥Ë' => 'ni',
               '¥Ì' => 'nu',
               '¥Í' => 'ne',
               '¥Ó¥ã' => 'bya',
               '¥Î' => 'no',
               '¥Ï' => 'ha',
               '¥Ó¥å' => 'byu',
               '¥Ð' => 'ba',
               '¥Ñ' => 'pa',
               '¥Ó¥ç' => 'byo',
               '¥Ò' => 'hi',
               '¥Ó' => 'bi',
               '¥Ô' => 'pi',
               '¥Õ' => 'hu',
               '¥Á¥ã' => 'tya',
               '¥Ö' => 'bu',
               '¥×' => 'pu',
               '¥Á¥å' => 'tyu',
               '¥Ø' => 'he',
               '¥Ù' => 'be',
               '¥Á¥ç' => 'tyo',
               '¥Ú' => 'pe',
               '¥­¥§' => 'kye',
               '¥Û' => 'ho',
               '¥Ü' => 'bo',
               '¥Ý' => 'po',
               '¥Þ' => 'ma',
               '¥ß' => 'mi',
               '¥à' => 'mu',
               '¥á' => 'me',
               '¥â' => 'mo',
               '¥ã' => 'xya',
               '¥ä' => 'ya',
               '¥å' => 'xyu',
               '¥Ç¥£' => 'di',
               '¥æ' => 'yu',
               '¥ç' => 'xyo',
               '¥è' => 'yo',
               '¥é' => 'ra',
               '¥Ç¥§' => 'dye',
               '¥ê' => 'ri',
               '¥ë' => 'ru',
               '¥ì' => 're',
               '¥í' => 'ro',
               '¥î' => 'xwa',
               '¥ï' => 'wa',
               '¥ð' => 'wi',
               '¥ñ' => 'we',
               '¥Ô¥§' => 'pye',
               '¥ò' => 'wo',
               '¥ó' => 'q',
               '¥ô' => 'vu',
               '¥õ' => 'xka',
               '¥ö' => 'xke',
               '¥·¥ã' => 'sya',
               '¥·¥å' => 'syu',
               '¥Â¥§' => 'dje',
               '¥·¥ç' => 'syo',
               '¥­¥ã' => 'kya'
             );
%Lingua::JA::Romaji::roma = (
           'fo' => {
                     'kata' => '¥Õ¥©',
                     'hira' => '¤Õ¤©'
                   },
           'fyu' => {
                      'kata' => '¥Õ¥å',
                      'hira' => '¤Õ¤å'
                    },
           'na' => {
                     'kata' => '¥Ê',
                     'hira' => '¤Ê'
                   },
           'syo' => {
                      'kata' => '¥·¥ç',
                      'hira' => '¤·¤ç'
                    },
           'fu' => {
                     'kata' => '¥Õ',
                     'hira' => '¤Õ'
                   },
           'ne' => {
                     'kata' => '¥Í',
                     'hira' => '¤Í'
                   },
           'nya' => {
                      'kata' => '¥Ë¥ã',
                      'hira' => '¤Ë¤ã'
                    },
           'xka' => {
                      'kata' => '¥õ'
                    },
           'nye' => {
                      'kata' => '¥Ë¥§',
                      'hira' => '¤Ë¤§'
                    },
           'ni' => {
                     'kata' => '¥Ë',
                     'hira' => '¤Ë'
                   },
           'syu' => {
                      'kata' => '¥·¥å',
                      'hira' => '¤·¤å'
                    },
           'xke' => {
                      'kata' => '¥ö'
                    },
           'no' => {
                     'kata' => '¥Î',
                     'hira' => '¤Î'
                   },
           'va' => {
                     'kata' => '¥ô¥¡',
                     'hira' => '¥ô¤¡'
                   },
           'nyo' => {
                      'kata' => '¥Ë¥ç',
                      'hira' => '¤Ë¤ç'
                    },
           'ga' => {
                     'kata' => '¥¬',
                     'hira' => '¤¬'
                   },
           've' => {
                     'kata' => '¥ô¥§',
                     'hira' => '¥ô¤§'
                   },
           'nu' => {
                     'kata' => '¥Ì',
                     'hira' => '¤Ì'
                   },
           'ge' => {
                     'kata' => '¥²',
                     'hira' => '¤²'
                   },
           'vi' => {
                     'kata' => '¥ô¥£',
                     'hira' => '¥ô¤£'
                   },
           'nyu' => {
                      'kata' => '¥Ë¥å',
                      'hira' => '¤Ë¤å'
                    },
           'gi' => {
                     'kata' => '¥®',
                     'hira' => '¤®'
                   },
           'vo' => {
                     'kata' => '¥ô¥©',
                     'hira' => '¥ô¤©    '
                   },
           'go' => {
                     'kata' => '¥´',
                     'hira' => '¤´'
                   },
           'vu' => {
                     'kata' => '¥ô',
                     'hira' => '¥ô'
                   },
           'dya' => {
                      'kata' => '¥Ç¥ã',
                      'hira' => '¤Ç¤ã'
                    },
           'gu' => {
                     'kata' => '¥°',
                     'hira' => '¤°'
                   },
           'dja' => {
                      'kata' => '¥Â¥ã',
                      'hira' => '¤Â¤ã'
                    },
           '*' => {
                    'kata' => '¥Ã',
                    'hira' => '¤Ã'
                  },
           'dye' => {
                      'kata' => '¥Ç¥§',
                      'hira' => '¤Ç¤§'
                    },
           'dje' => {
                      'kata' => '¥Â¥§',
                      'hira' => '¤Â¤§'
                    },
           '-' => {
                    'kata' => '¡¼',
                    'hira' => '¡¼'
                  },
           '.' => {
                    'kata' => '¡¦',
                    'hira' => '¡¦'
                  },
           'dji' => {
                      'kata' => '¥Â',
                      'hira' => '¤Â'
                    },
           'wa' => {
                     'kata' => '¥ï',
                     'hira' => '¤ï'
                   },
           'ha' => {
                     'kata' => '¥Ï',
                     'hira' => '¤Ï'
                   },
           'dyo' => {
                      'kata' => '¥Ç¥ç',
                      'hira' => '¤Ç¤ç'
                    },
           'djo' => {
                      'kata' => '¥Â¥ç',
                      'hira' => '¤Â¤ç'
                    },
           'we' => {
                     'kata' => '¥ñ',
                     'hira' => '¤ñ'
                   },
           'he' => {
                     'kata' => '¥Ø',
                     'hira' => '¤Ø'
                   },
           'dyu' => {
                      'kata' => '¥Ç¥å',
                      'hira' => '¤Ç¤å'
                    },
           'wi' => {
                     'kata' => '¥ð',
                     'hira' => '¤ð'
                   },
           'hi' => {
                     'kata' => '¥Ò',
                     'hira' => '¤Ò'
                   },
           'dju' => {
                      'kata' => '¥Â¥å',
                      'hira' => '¤Â¤å'
                    },
           'wo' => {
                     'kata' => '¥ò',
                     'hira' => '¤ò'
                   },
           'ho' => {
                     'kata' => '¥Û',
                     'hira' => '¤Û'
                   },
           'pa' => {
                     'kata' => '¥Ñ',
                     'hira' => '¤Ñ'
                   },
           'dza' => {
                      'kata' => '¥Â¥ã',
                      'hira' => '¤Â¤ã'
                    },
           'pe' => {
                     'kata' => '¥Ú',
                     'hira' => '¤Ú'
                   },
           'hu' => {
                     'kata' => '¥Õ',
                     'hira' => '¤Õ'
                   },
           'pi' => {
                     'kata' => '¥Ô',
                     'hira' => '¤Ô'
                   },
           'dze' => {
                      'kata' => '¥Â¥§',
                      'hira' => '¤Â¤§'
                    },
           'gya' => {
                      'kata' => '¥®¥ã',
                      'hira' => '¤®¤ã'
                    },
           'dzi' => {
                      'kata' => '¥Â',
                      'hira' => '¤Â'
                    },
           'po' => {
                     'kata' => '¥Ý',
                     'hira' => '¤Ý'
                   },
           'gye' => {
                      'kata' => '¥®¥§',
                      'hira' => '¤®¤§'
                    },
           'tcha' => {
                       'kata' => '¥Ã¥Á¥ã',
                       'hira' => '¤Ã¤Á¤ã'
                     },
           'xa' => {
                     'kata' => '¥¡',
                     'hira' => '¤¡'
                   },
           'dzo' => {
                      'kata' => '¥Â¥ç',
                      'hira' => '¤Â¤ç'
                    },
           'tya' => {
                      'kata' => '¥Á¥ã',
                      'hira' => '¤Á¤ã'
                    },
           'tche' => {
                       'kata' => '¥Ã¥Á¥§',
                       'hira' => '¤Ã¤Á¤§'
                     },
           'xe' => {
                     'kata' => '¥§',
                     'hira' => '¤§'
                   },
           'pu' => {
                     'kata' => '¥×',
                     'hira' => '¤×'
                   },
           'tye' => {
                      'kata' => '¥Á¥§',
                      'hira' => '¤Á¤§'
                    },
           'dzu' => {
                      'kata' => '¥Å',
                      'hira' => '¤Å'
                    },
           'tchi' => {
                       'kata' => '¥Ã¥Á',
                       'hira' => '¤Ã¤Á'
                     },
           'gyo' => {
                      'kata' => '¥®¥ç',
                      'hira' => '¤®¤ç'
                    },
           'xi' => {
                     'kata' => '¥£',
                     'hira' => '¤£'
                   },
           'tyi' => {
                      'kata' => '¥Á',
                      'hira' => '¤Á'
                    },
           'bya' => {
                      'kata' => '¥Ó¥ã',
                      'hira' => '¤Ó¤ã'
                    },
           'a' => {
                    'kata' => '¥¢',
                    'hira' => '¤¢'
                  },
           'tcho' => {
                       'kata' => '¥Ã¥Á¥ç',
                       'hira' => '¤Ã¤Á¤ç'
                     },
           'gyu' => {
                      'kata' => '¥®¥å',
                      'hira' => '¤®¤å'
                    },
           'xo' => {
                     'kata' => '¥©',
                     'hira' => '¤©'
                   },
           'bye' => {
                      'kata' => '¥Ó¥§',
                      'hira' => '¤Ó¤§'
                    },
           'tyo' => {
                      'kata' => '¥Á¥ç',
                      'hira' => '¤Á¤ç'
                    },
           'e' => {
                    'kata' => '¥¨',
                    'hira' => '¤¨'
                  },
           'ba' => {
                     'kata' => '¥Ð',
                     'hira' => '¤Ð'
                   },
           'tchu' => {
                       'kata' => '¥Ã¥Á¥å',
                       'hira' => '¤Ã¤Á¤å'
                     },
           'i' => {
                    'kata' => '¥¤',
                    'hira' => '¤¤'
                  },
           'xu' => {
                     'kata' => '¥¥',
                     'hira' => '¤¥'
                   },
           'tyu' => {
                      'kata' => '¥Á¥å',
                      'hira' => '¤Á¤å'
                    },
           'be' => {
                     'kata' => '¥Ù',
                     'hira' => '¤Ù'
                   },
           'byo' => {
                      'kata' => '¥Ó¥ç',
                      'hira' => '¤Ó¤ç'
                    },
           'o' => {
                    'kata' => '¥ª',
                    'hira' => '¤ª'
                  },
           'bi' => {
                     'kata' => '¥Ó',
                     'hira' => '¤Ó'
                   },
           'q' => {
                    'kata' => '¥ó',
                    'hira' => '¤ó'
                  },
           'byu' => {
                      'kata' => '¥Ó¥å',
                      'hira' => '¤Ó¤å'
                    },
           'u' => {
                    'kata' => '¥¦',
                    'hira' => '¤¦'
                  },
           'ya' => {
                     'kata' => '¥ä',
                     'hira' => '¤ä'
                   },
           'bo' => {
                     'kata' => '¥Ü',
                     'hira' => '¤Ü'
                   },
           'ja' => {
                     'kata' => '¥¸¥ã',
                     'hira' => '¤¸¤ã'
                   },
           'jya' => {
                      'kata' => '¥¸¥ã',
                      'hira' => '¤¸¤ã'
                    },
           'ye' => {
                     'kata' => '¥¨',
                     'hira' => '¤¨'
                   },
           'bu' => {
                     'kata' => '¥Ö',
                     'hira' => '¤Ö'
                   },
           'je' => {
                     'kata' => '¥¸¥§',
                     'hira' => '¤¸¤§'
                   },
           'jye' => {
                      'kata' => '¥¸¥§',
                      'hira' => '¤¸¤§'
                    },
           'ji' => {
                     'kata' => '¥¸',
                     'hira' => '¤¸'
                   },
           'jyi' => {
                      'kata' => '¥¸',
                      'hira' => '¤¸'
                    },
           'cha' => {
                      'kata' => '¥Á¥ã',
                      'hira' => '¤Á¤ã'
                    },
           'che' => {
                      'kata' => '¥Á¥§',
                      'hira' => '¤Á¤§'
                    },
           'yo' => {
                     'kata' => '¥è',
                     'hira' => '¤è'
                   },
           'jo' => {
                     'kata' => '¥¸¥ç',
                     'hira' => '¤¸¤ç'
                   },
           'jyo' => {
                      'kata' => '¥¸¥ç',
                      'hira' => '¤¸¤ç'
                    },
           'ra' => {
                     'kata' => '¥é',
                     'hira' => '¤é'
                   },
           'chi' => {
                      'kata' => '¥Á',
                      'hira' => '¤Á'
                    },
           'tsa' => {
                      'kata' => '¥Ä¥¡',
                      'hira' => '¤Ä¤¡'
                    },
           'yu' => {
                     'kata' => '¥æ',
                     'hira' => '¤æ'
                   },
           're' => {
                     'kata' => '¥ì',
                     'hira' => '¤ì'
                   },
           'ju' => {
                     'kata' => '¥¸¥å',
                     'hira' => '¤¸¤å'
                   },
           'jyu' => {
                      'kata' => '¥¸¥å',
                      'hira' => '¤¸¤å'
                    },
           'cho' => {
                      'kata' => '¥Á¥ç',
                      'hira' => '¤Á¤ç'
                    },
           'tse' => {
                      'kata' => '¥Ä¥§',
                      'hira' => '¤Ä¤§'
                    },
           'rya' => {
                      'kata' => '¥ê¥ã',
                      'hira' => '¤ê¤ã'
                    },
           'ri' => {
                     'kata' => '¥ê',
                     'hira' => '¤ê'
                   },
           'rye' => {
                      'kata' => '¥ê¥§',
                      'hira' => '¤ê¤§'
                    },
           'chu' => {
                      'kata' => '¥Á¥å',
                      'hira' => '¤Á¤å'
                    },
           'ro' => {
                     'kata' => '¥í',
                     'hira' => '¤í'
                   },
           't-' => {
                     'kata' => '¥Ã',
                     'hira' => '¤Ã'
                   },
           'za' => {
                     'kata' => '¥¶',
                     'hira' => '¤¶'
                   },
           'tso' => {
                      'kata' => '¥Ä¥©',
                      'hira' => '¤Ä¤©'
                    },
           'ka' => {
                     'kata' => '¥«',
                     'hira' => '¤«'
                   },
           'ze' => {
                     'kata' => '¥¼',
                     'hira' => '¤¼'
                   },
           'ru' => {
                     'kata' => '¥ë',
                     'hira' => '¤ë'
                   },
           'xwa' => {
                      'kata' => '¥î',
                      'hira' => '¤î'
                    },
           'ryo' => {
                      'kata' => '¥ê¥ç',
                      'hira' => '¤ê¤ç'
                    },
           'ke' => {
                     'kata' => '¥±',
                     'hira' => '¤±'
                   },
           'tsu' => {
                      'kata' => '¥Ä',
                      'hira' => '¤Ä'
                    },
           'mya' => {
                      'kata' => '¥ß¥ã',
                      'hira' => '¤ß¤ã'
                    },
           'zi' => {
                     'kata' => '¥¸',
                     'hira' => '¤¸'
                   },
           'ki' => {
                     'kata' => '¥­',
                     'hira' => '¤­'
                   },
           'ryu' => {
                      'kata' => '¥ê¥å',
                      'hira' => '¤ê¤å'
                    },
           'mye' => {
                      'kata' => '¥ß¥§',
                      'hira' => '¤ß¤§'
                    },
           'zo' => {
                     'kata' => '¥¾',
                     'hira' => '¤¾'
                   },
           'ko' => {
                     'kata' => '¥³',
                     'hira' => '¤³'
                   },
           'sa' => {
                     'kata' => '¥µ',
                     'hira' => '¤µ'
                   },
           'da' => {
                     'kata' => '¥À',
                     'hira' => '¤À'
                   },
           'zu' => {
                     'kata' => '¥º',
                     'hira' => '¤º'
                   },
           'se' => {
                     'kata' => '¥»',
                     'hira' => '¤»'
                   },
           'myo' => {
                      'kata' => '¥ß¥ç',
                      'hira' => '¤ß¤ç'
                    },
           'ku' => {
                     'kata' => '¥¯',
                     'hira' => '¤¯'
                   },
           'sha' => {
                      'kata' => '¥·¥ã',
                      'hira' => '¤·¤ã'
                    },
           'de' => {
                     'kata' => '¥Ç',
                     'hira' => '¤Ç'
                   },
           'si' => {
                     'kata' => '¥·',
                     'hira' => '¤·'
                   },
           'hya' => {
                      'kata' => '¥Ò¥ã',
                      'hira' => '¤Ò¤ã'
                    },
           'di' => {
                     'kata' => '¥Ç¥£',
                     'hira' => '¤Ç¤£'
                   },
           'myu' => {
                      'kata' => '¥ß¥å',
                      'hira' => '¤ß¤å'
                    },
           'she' => {
                      'kata' => '¥·¥§',
                      'hira' => '¤·¤§'
                    },
           'hye' => {
                      'kata' => '¥Ò¥§',
                      'hira' => '¤Ò¤§'
                    },
           'shi' => {
                      'kata' => '¥·',
                      'hira' => '¤·'
                    },
           'so' => {
                     'kata' => '¥½',
                     'hira' => '¤½'
                   },
           'do' => {
                     'kata' => '¥É',
                     'hira' => '¤É'
                   },
           'su' => {
                     'kata' => '¥¹',
                     'hira' => '¤¹'
                   },
           'sho' => {
                      'kata' => '¥·¥ç',
                      'hira' => '¤·¤ç'
                    },
           'du' => {
                     'kata' => '¥É¥¥',
                     'hira' => '¤É¤¥'
                   },
           'hyo' => {
                      'kata' => '¥Ò¥ç',
                      'hira' => '¤Ò¤ç'
                    },
           'cya' => {
                      'kata' => '¥Á¥ã',
                      'hira' => '¤Á¤ã'
                    },
           'n\'' => {
                      'kata' => '¥ó',
                      'hira' => '¤ó'
                    },
           'shu' => {
                      'kata' => '¥·¥å',
                      'hira' => '¤·¤å'
                    },
           'hyu' => {
                      'kata' => '¥Ò¥å',
                      'hira' => '¤Ò¤å'
                    },
           'cye' => {
                      'kata' => '¥Á¥§',
                      'hira' => '¤Á¤§'
                    },
           'pya' => {
                      'kata' => '¥Ô¥ã',
                      'hira' => '¤Ô¤ã'
                    },
           'cyi' => {
                      'kata' => '¥Á',
                      'hira' => '¤Á'
                    },
           'ta' => {
                     'kata' => '¥¿',
                     'hira' => '¤¿'
                   },
           'pye' => {
                      'kata' => '¥Ô¥§',
                      'hira' => '¤Ô¤§'
                    },
           'te' => {
                     'kata' => '¥Æ',
                     'hira' => '¤Æ'
                   },
           'cyo' => {
                      'kata' => '¥Á¥ç',
                      'hira' => '¤Á¤ç'
                    },
           'ti' => {
                     'kata' => '¥Á',
                     'hira' => '¤Á'
                   },
           'cyu' => {
                      'kata' => '¥Á¥å',
                      'hira' => '¤Á¤å'
                    },
           'pyo' => {
                      'kata' => '¥Ô¥ç',
                      'hira' => '¤Ô¤ç'
                    },
           'kya' => {
                      'kata' => '¥­¥ã',
                      'hira' => '¤­¤ã'
                    },
           'to' => {
                     'kata' => '¥È',
                     'hira' => '¤È'
                   },
           'ma' => {
                     'kata' => '¥Þ',
                     'hira' => '¤Þ'
                   },
           'pyu' => {
                      'kata' => '¥Ô¥å',
                      'hira' => '¤Ô¤å'
                    },
           'kye' => {
                      'kata' => '¥­¥§',
                      'hira' => '¤­¤§'
                    },
           'tu' => {
                     'kata' => '¥Ä',
                     'hira' => '¤Ä'
                   },
           'xya' => {
                      'kata' => '¥ã',
                      'hira' => '¤ã'
                    },
           'me' => {
                     'kata' => '¥á',
                     'hira' => '¤á'
                   },
           'mi' => {
                     'kata' => '¥ß',
                     'hira' => '¤ß'
                   },
           'kyo' => {
                      'kata' => '¥­¥ç',
                      'hira' => '¤­¤ç'
                    },
           'mo' => {
                     'kata' => '¥â',
                     'hira' => '¤â'
                   },
           'fya' => {
                      'kata' => '¥Õ¥ã',
                      'hira' => '¤Õ¤ã'
                    },
           'kyu' => {
                      'kata' => '¥­¥å',
                      'hira' => '¤­¤å'
                    },
           'fye' => {
                      'kata' => '¥Õ¥§',
                      'hira' => '¤Õ¤§'
                    },
           'fa' => {
                     'kata' => '¥Õ¥¡',
                     'hira' => '¤Õ¤¡'
                   },
           'xyo' => {
                      'kata' => '¥ç',
                      'hira' => '¤ç'
                    },
           'mu' => {
                     'kata' => '¥à',
                     'hira' => '¤à'
                   },
           'sya' => {
                      'kata' => '¥·¥ã',
                      'hira' => '¤·¤ã'
                    },
           'fe' => {
                     'kata' => '¥Õ¥§',
                     'hira' => '¤Õ¤§'
                   },
           'xyu' => {
                      'kata' => '¥å',
                      'hira' => '¤å'
                    },
           'sye' => {
                      'kata' => '¥·¥§',
                      'hira' => '¤·¤§'
                    },
           'fi' => {
                     'kata' => '¥Õ¥£',
                     'hira' => '¤Õ¤£'
                   },
           'fyo' => {
                      'kata' => '¥Õ¥ç',
                      'hira' => '¤Õ¤ç'
                    },
           'syi' => {
                      'kata' => '¥·',
                      'hira' => '¤·'
                    }
         );
%Lingua::JA::Romaji::allkana = (
              '¥­¥å' => 'kyu',
              '¥¸¥§' => 'je',
              '¥­¥ç' => 'kyo',
              '¥Ç¥ã' => 'dya',
              '¥Ç¥å' => 'dyu',
              '¥Ò¥§' => 'hye',
              '¥Ç¥ç' => 'dyo',
              '¥Â¥ã' => 'dza',
              '¥Â¥å' => 'dju',
              '¥Â¥ç' => 'dzo',
              '¥®¥§' => 'gye',
              '¤Ô¤ã' => 'pya',
              '¤Ô¤å' => 'pyu',
              '¤ß¤§' => 'mye',
              '¤Ô¤ç' => 'pyo',
              '¥¸¥ã' => 'ja',
              '¥¸¥å' => 'ju',
              '¥¸¥ç' => 'jo',
              '¤Õ¤¡' => 'fa',
              '¥Ò¥ã' => 'hya',
              '¤Õ¤£' => 'fi',
              '¥Ò¥å' => 'hyu',
              '¥Ò¥ç' => 'hyo',
              '¤Õ¤§' => 'fe',
              '¤Õ¤©' => 'fo',
              '¥Ã¥Á' => 'tchi',
              '¥®¥ã' => 'gya',
              '¥®¥å' => 'gyu',
              '¥®¥ç' => 'gyo',
              '¤ß¤ã' => 'mya',
              '¤ß¤å' => 'myu',
              '¤ê¤§' => 'rye',
              '¥Ó¥§' => 'bye',
              '¤ß¤ç' => 'myo',
              '¤Ë¤§' => 'nye',
              '¤Ã¤Á¤§' => 'tche',
              '¤Õ¤ã' => 'fya',
              '¥É¥¥' => 'du',
              '¤Õ¤å' => 'fyu',
              '¤Õ¤ç' => 'fyo',
              '¤Á¤§' => 'che',
              '¥Ä¥¡' => 'tsa',
              '¥Ä¥§' => 'tse',
              '¥Ä¥©' => 'tso',
              '¤ê¤ã' => 'rya',
              '¥Ó¥ã' => 'bya',
              '¤ê¤å' => 'ryu',
              '¤Ë¤ã' => 'nya',
              '¥Ó¥å' => 'byu',
              '¤ê¤ç' => 'ryo',
              '¤Ë¤å' => 'nyu',
              '¥Ó¥ç' => 'byo',
              '¤Ã¤Á¤ã' => 'tcha',
              '¤Ë¤ç' => 'nyo',
              '¤·¤§' => 'she',
              '¤Ã¤Á¤å' => 'tchu',
              '¤Ã¤Á¤ç' => 'tcho',
              '¤Á¤ã' => 'cha',
              '¥Ô¥§' => 'pye',
              '¤Á¤å' => 'chu',
              '¤Á¤ç' => 'cho',
              '¤­¤§' => 'kye',
              '¤Ç¤£' => 'di',
              '¤Ç¤§' => 'dye',
              '¤·¤ã' => 'sha',
              '¤·¤å' => 'shu',
              '¤Â¤§' => 'dze',
              '¤·¤ç' => 'sho',
              '¡¦' => '.',
              '¥Ô¥ã' => 'pya',
              '¥Ô¥å' => 'pyu',
              '¥ß¥§' => 'mye',
              '¤­¤ã' => 'kya',
              '¡¼' => '-',
              '¥Ô¥ç' => 'pyo',
              '¤­¤å' => 'kyu',
              '¤­¤ç' => 'kyo',
              '¤¸¤§' => 'je',
              '¤Ç¤ã' => 'dya',
              '¤Ç¤å' => 'dyu',
              '¤Ç¤ç' => 'dyo',
              '¤Ò¤§' => 'hye',
              '¥ô¥¡' => 'va',
              '¥ô¥£' => 'vi',
              '¥ô¤¡' => 'va',
              '¥ô¤£' => 'vi',
              '¥Õ¥¡' => 'fa',
              '¥Õ¥£' => 'fi',
              '¥ô¥§' => 've',
              '¥ô¤§' => 've',
              '¤Â¤ã' => 'dza',
              '¥ô¥©' => 'vo',
              '¥ô¤©' => 'vo',
              '¥Õ¥§' => 'fe',
              '¤Â¤å' => 'dju',
              '¥Õ¥©' => 'fo',
              '¤Â¤ç' => 'dzo',
              '¤®¤§' => 'gye',
              '¥Ã¥Á¥§' => 'tche',
              '¥ß¥ã' => 'mya',
              '¥ß¥å' => 'myu',
              '¥ê¥§' => 'rye',
              '¥ß¥ç' => 'myo',
              '¤¸¤ã' => 'ja',
              '¥Ë¥§' => 'nye',
              '¤¸¤å' => 'ju',
              '¤¸¤ç' => 'jo',
              '¤¡' => 'xa',
              '¤¢' => 'a',
              '¤£' => 'xi',
              '¤¤' => 'i',
              '¤¥' => 'xu',
              '¤¦' => 'u',
              '¤Ò¤ã' => 'hya',
              '¤§' => 'xe',
              '¤¨' => 'e',
              '¤Ò¤å' => 'hyu',
              '¤©' => 'xo',
              '¤ª' => 'o',
              '¤«' => 'ka',
              '¤Ò¤ç' => 'hyo',
              '¤¬' => 'ga',
              '¤­' => 'ki',
              '¤®' => 'gi',
              '¤¯' => 'ku',
              '¤°' => 'gu',
              '¤±' => 'ke',
              '¤²' => 'ge',
              '¤³' => 'ko',
              '¤´' => 'go',
              '¤µ' => 'sa',
              '¥Õ¥ã' => 'fya',
              '¤Ã¤Á' => 'tchi',
              '¤¶' => 'za',
              '¤·' => 'shi',
              '¥Õ¥å' => 'fyu',
              '¤¸' => 'ji',
              '¤¹' => 'su',
              '¤®¤ã' => 'gya',
              '¥Õ¥ç' => 'fyo',
              '¤º' => 'zu',
              '¤»' => 'se',
              '¤®¤å' => 'gyu',
              '¥Á¥§' => 'che',
              '¤¼' => 'ze',
              '¤®¤ç' => 'gyo',
              '¤½' => 'so',
              '¤¾' => 'zo',
              '¤¿' => 'ta',
              '¤À' => 'da',
              '¥Ã¥Á¥ã' => 'tcha',
              '¤Á' => 'chi',
              '¤Â' => 'dzi',
              '¥¡' => 'xa',
              '¥Ã¥Á¥å' => 'tchu',
              '¤Ã' => '*',
              '¥¢' => 'a',
              '¤Ä' => 'tsu',
              '¥£' => 'xi',
              '¥Ã¥Á¥ç' => 'tcho',
              '¤Å' => 'dzu',
              '¥¤' => 'i',
              '¤Æ' => 'te',
              '¥¥' => 'xu',
              '¤Ç' => 'de',
              '¥¦' => 'u',
              '¤È' => 'to',
              '¥§' => 'xe',
              '¤É' => 'do',
              '¥¨' => 'e',
              '¤Ê' => 'na',
              '¥©' => 'xo',
              '¤Ó¤§' => 'bye',
              '¤Ë' => 'ni',
              '¥ª' => 'o',
              '¤Ì' => 'nu',
              '¥«' => 'ka',
              '¤Í' => 'ne',
              '¥¬' => 'ga',
              '¤Î' => 'no',
              '¥­' => 'ki',
              '¤Ï' => 'ha',
              '¥®' => 'gi',
              '¤Ð' => 'ba',
              '¥¯' => 'ku',
              '¤Ñ' => 'pa',
              '¥°' => 'gu',
              '¤Ò' => 'hi',
              '¥±' => 'ke',
              '¤Ó' => 'bi',
              '¥²' => 'ge',
              '¥ê¥ã' => 'rya',
              '¤Ô' => 'pi',
              '¥³' => 'ko',
              '¤Õ' => 'fu',
              '¥´' => 'go',
              '¥ê¥å' => 'ryu',
              '¤Ö' => 'bu',
              '¥µ' => 'sa',
              '¥Ë¥ã' => 'nya',
              '¤×' => 'pu',
              '¥¶' => 'za',
              '¥ê¥ç' => 'ryo',
              '¤Ø' => 'he',
              '¥·' => 'shi',
              '¥Ë¥å' => 'nyu',
              '¤Ù' => 'be',
              '¥¸' => 'ji',
              '¤Ú' => 'pe',
              '¥¹' => 'su',
              '¥Ë¥ç' => 'nyo',
              '¤Û' => 'ho',
              '¥º' => 'zu',
              '¥·¥§' => 'she',
              '¤Ü' => 'bo',
              '¥»' => 'se',
              '¤Ý' => 'po',
              '¥¼' => 'ze',
              '¤Þ' => 'ma',
              '¥½' => 'so',
              '¤ß' => 'mi',
              '¥¾' => 'zo',
              '¤à' => 'mu',
              '¥¿' => 'ta',
              '¤á' => 'me',
              '¥À' => 'da',
              '¤â' => 'mo',
              '¥Á' => 'chi',
              '¤ã' => 'xya',
              '¥Â' => 'dzi',
              '¤ä' => 'ya',
              '¥Ã' => '*',
              '¤å' => 'xyu',
              '¥Ä' => 'tsu',
              '¤æ' => 'yu',
              '¥Å' => 'dzu',
              '¤ç' => 'xyo',
              '¥Æ' => 'te',
              '¤è' => 'yo',
              '¥Ç' => 'de',
              '¤É¤¥' => 'du',
              '¤é' => 'ra',
              '¥È' => 'to',
              '¤ê' => 'ri',
              '¥É' => 'do',
              '¤ë' => 'ru',
              '¥Ê' => 'na',
              '¤ì' => 're',
              '¥Ë' => 'ni',
              '¤í' => 'ro',
              '¥Ì' => 'nu',
              '¤î' => 'xwa',
              '¥Í' => 'ne',
              '¤ï' => 'wa',
              '¥Î' => 'no',
              '¤ð' => 'wi',
              '¥Ï' => 'ha',
              '¤ñ' => 'we',
              '¥Ð' => 'ba',
              '¤ò' => 'wo',
              '¥Ñ' => 'pa',
              '¤ó' => 'n\'',
              '¥Ò' => 'hi',
              '¥Ó' => 'bi',
              '¥Ô' => 'pi',
              '¥Õ' => 'fu',
              '¤Ä¤¡' => 'tsa',
              '¥Ö' => 'bu',
              '¥Á¥ã' => 'cha',
              '¥×' => 'pu',
              '¥Ø' => 'he',
              '¥Á¥å' => 'chu',
              '¥Ù' => 'be',
              '¥Ú' => 'pe',
              '¥Á¥ç' => 'cho',
              '¤Ä¤§' => 'tse',
              '¥­¥§' => 'kye',
              '¥Û' => 'ho',
              '¥Ü' => 'bo',
              '¤Ä¤©' => 'tso',
              '¥Ý' => 'po',
              '¥Þ' => 'ma',
              '¥ß' => 'mi',
              '¥à' => 'mu',
              '¥á' => 'me',
              '¥â' => 'mo',
              '¥ã' => 'xya',
              '¥ä' => 'ya',
              '¥å' => 'xyu',
              '¤Ó¤ã' => 'bya',
              '¥Ç¥£' => 'di',
              '¥æ' => 'yu',
              '¥ç' => 'xyo',
              '¥è' => 'yo',
              '¤Ó¤å' => 'byu',
              '¥é' => 'ra',
              '¥Ç¥§' => 'dye',
              '¥ê' => 'ri',
              '¤Ó¤ç' => 'byo',
              '¥ë' => 'ru',
              '¥ì' => 're',
              '¥í' => 'ro',
              '¥î' => 'xwa',
              '¥ï' => 'wa',
              '¥ð' => 'wi',
              '¥ñ' => 'we',
              '¥ò' => 'wo',
              '¥ó' => 'n\'',
              '¥ô' => 'vu',
              '¥õ' => 'xka',
              '¥ö' => 'xke',
              '¥·¥ã' => 'sha',
              '¥·¥å' => 'shu',
              '¥Â¥§' => 'dze',
              '¥·¥ç' => 'sho',
              '¤Ô¤§' => 'pye',
              '¥­¥ã' => 'kya'
            );


1;
__END__
# Below is stub documentation for your module. You better edit it!

