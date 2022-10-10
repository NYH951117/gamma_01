#!/usr/bin/perl
use FileHandle;
use File::Basename;
use Getopt::Long;
use File::Copy;

if (($#ARGV + 1) < 1){die <<EOS ;}
*** $0

usage: $0 [options] <SARFILE> 
    SARFILE   (input)  Input SAR file to process 
    -m <num matches>   Set the number of matches to use
    -o <max offset>    Set the maximum allowable offset (meters)

EOS

GetOptions ('m=i' => \$matches_flg,'o=i' => \$offset_flg );


$arg = $ARGV[0];
($sarfile,$path) = fileparse($arg);

$min_matches = 50;
$max_offset = 50;

if ($matches_flg != 0) {
  print "Setting minimum number of matches to $matches_flg\n";
  $min_matches = $matches_flg;
}

if ($offset_flg != 0) {
  print "Setting maximum offset to be $offset_flg\n";
  $max_offset = $offset_flg;
}

$filehv = $sarfile;
$filehv =~ s/HH/HV/;
$filevh = $sarfile;
$filevh =~ s/HH/VH/;
$filevv = $sarfile;
$filevv =~ s/HH/VV/;

$mode = "FBS";
$post = 6.25;
if (-e $filehv) {
  $mode = "FBD";
  $post = 12.5;
  if (-e $filevv) {
    $mode = "PLR";
    $post = 12.5;
  }
}

open(LOG,">>coreg_check.log") or die "\nERROR $0: cannot open log file: coreg_check.log\n";
print LOG "SAR file: $sarfile\n";
print LOG "Checking for $min_matches matches and $max_offset offset\n";

if (-e "geo_HH/mk_geo_radcal_2.log") { $platform = "ALOS"; $log = "geo_HH/mk_geo_radcal_2.log"; }
elsif (-e "geo/mk_geo_radcal_2.log") { $log = "geo/mk_geo_radcal_2.log"; $post = 12.5; }
else { die "ERROR $0: Can't find mk_geo_radcal_2.log file\n"; }

if  (-e $log) {
  open(TLOG,$log) or die "ERROR $0: could not open log: $log: $!\n\n";
  my (@lines) = <TLOG>;
  close(TLOG);

  while (my $line = shift(@lines)) {
    if ($line =~ /final solution:\s+(\S+)/) {
      $matches = $1;
      print LOG "Number of matches is $matches\n";
      if ($matches < $min_matches) {
#        print LOG "WARNING: not enough matches, using dead reckoning\n";
        print LOG "Granule failed coregistration\n";
        $ret = -1;
        close LOG;
        exit $ret;
      } 
    }
    if ($line =~ /final range offset poly. coeff.:\s+(\S+)\s+(\S+)\s+(\S+)/) {
      $r1 = $1;
      $r2 = $2;
      $r3 = $3;
      print LOG "Range polynomial is $r1 $r2 $r3\n";
    }
    if ($line =~ /final azimuth offset poly. coeff.:\s+(\S+)\s+(\S+)\s+(\S+)/) {
      $a1 = $1;
      $a2 = $2;
      $a3 = $3;
      print LOG "Azimuth polynomial is $a1 $a2 $a3\n";
    }
  }
}

$log = glob('geo_HH/*.diff_par');
if (-e $log) { $platform = "ALOS"; }
else {
  $log = glob('geo/*.diff_par');
  if (-e $log) { $platform = "LEGACY"; }
  else { die "ERROR $0: Can't find diff_par file\n"; }
}

if (-e $log) {
  open(TLOG,$log) or die "ERROR $0: could not open log: $log: $!\n\n";
  my (@lines) = <TLOG>;
  close(TLOG);

  while (my $line = shift(@lines)) {
    if ($line =~ /range_samp_1:\s+(\S+)/) {
      $ns = $1;
      print LOG "Number of samples is $ns\n";
    }
    if ($line =~ /az_samp_1:\s+(\S+)/) {
      $nl = $1;
      print LOG "Number of lines is $nl\n";
    }
  }
} else { die "ERROR $0: Can't find diff par file $log\n"; }


# Point1 = 1, 1 
$rpt1 = $r1 + $r2 * 1 + $r3 * 1;
$apt1 = $a1 + $a2 * 1 + $a3 * 1;
$pt1 = sqrt($rpt1*$rpt1 + $apt1*$apt1);
print LOG "Point 1 offset is $pt1\n";

# Point2 = ns, 1
$rpt2 = $r1 + $r2 * $ns + $r3 * 1;
$apt2 = $a1 + $a2 * $ns + $a3 * 1;
$pt2 = sqrt($rpt2*$rpt2 + $apt2*$apt2);
print LOG "Point 2 offset is $pt2\n";

# Point3 = 1, nl
$rpt3 = $r1 + $r2 * 1 + $r3 * $nl;
$apt3 = $a1 + $a2 * 1 + $a3 * $nl;
$pt3 = sqrt($rpt3*$rpt3 + $apt3*$apt3);
print LOG "Point 3 offset is $pt3\n";

# Point4 = ns, nl
$rpt4 = $r1 + $r2 * $ns + $r3 * $nl;
$apt4 = $a1 + $a2 * $ns + $a3 * $nl;
$pt4 = sqrt($rpt4*$rpt4 + $apt4*$apt4);
print LOG "Point 4 offset is $pt4\n";

# Point5 = ns/2, nl/2
$rpt5 = $r1 + $r2 * $ns/2 + $r3 * $nl/2;
$apt5 = $a1 + $a2 * $ns/2 + $a3 * $nl/2;
$pt5 = sqrt($rpt5*$rpt5 + $apt5*$apt5);
print LOG "Point 5 offset is $pt5\n";

# Point6 = ns/2, nl
$rpt6 = $r1 + $r2 * $ns/2 + $r3 * $nl;
$apt6 = $a1 + $a2 * $ns/2 + $a3 * $nl;
$pt6 = sqrt($rpt6*$rpt6 + $apt6*$apt6);
print LOG "Point 6 offset is $pt6\n";

# Point7 = ns, nl/2
$rpt7 = $r1 + $r2 * $ns + $r3 * $nl/2;
$apt7 = $a1 + $a2 * $ns + $a3 * $nl/2;
$pt7 = sqrt($rpt7*$rpt7 + $apt7*$apt7);
print LOG "Point 7 offset is $pt7\n";

# Point8 = 1, nl/2
$rpt8 = $r1 + $r2 * 1 + $r3 * $nl/2;
$apt8 = $a1 + $a2 * 1 + $a3 * $nl/2;
$pt8 = sqrt($rpt8*$rpt8 + $apt8*$apt8);
print LOG "Point 8 offset is $pt8\n";

# Point9 = ns/2, 1
$rpt9 = $r1 + $r2 * $ns/2 + $r3 * 1;
$apt9 = $a1 + $a2 * $ns/2 + $a3 * 1;
$pt9 = sqrt($rpt9*$rpt9 + $apt9*$apt9);
print LOG "Point 9 offset is $pt9\n";

$top = max($pt1, $pt2, $pt3, $pt4, $pt5, $pt6, $pt7, $pt8, $pt9);
print LOG "Biggest offset is $top pixels\n";

$offset = $top * $post;
print LOG "Found absolute offset of $offset meters\n";
if ($offset < $max_offset) {
  print LOG "...keeping offset\n";
  $ret = 0;
} else {
  print LOG "WARNING: offset too large, using dead reckoning\n";
  $ret = -1;
}

if ($ret == 0) { print LOG "Granule passed coregistration\n"; }
else { print LOG "Granule failed coregistration\n"; }

close LOG;

exit $ret;

sub max {
    my ($max, @vars) = @_;
    for (@vars) {
        $max = $_ if $_ > $max;
    }
    return $max;
}

