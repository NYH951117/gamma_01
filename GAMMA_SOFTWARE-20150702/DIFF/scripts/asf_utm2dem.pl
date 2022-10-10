#!/usr/bin/env perl
use FileHandle;
use File::Basename;
use POSIX;
$log = "asf_utm2dem.log";

if (($#ARGV + 1) < 3){die <<EOS ;}
*** $0
*** Copyright 2013, Gamma Remote Sensing, v1.2 29-Apr-2013 clw ***
*** Convert UTM DEM (GeoTIFF) from ASF to Gamma DEM and DEM parameter files ***

usage: $0 <UTM_DEM> <DEM> <DEM_par>
    UTM_DEM   (input)  UTM DEM from ASF (GeoTIFF, 16-bit short integer)
    DEM       (output) DEM data (16-bit short integer)
    DEM_par   (output) Gamma DEM parameter file

EOS

$utm = $ARGV[0];
$dem     = $ARGV[1];
$dem_par = $ARGV[2];
$dem_par_in = "dem_par.in";
$utm_tmp= "utm_tmp";
my ($s1, $dir1, $ext1) = fileparse($utm, qr/\.[^.]*/); #extension is the last bit after the last period
print "basename: $s1\n";

print "ASF DEM in GEOTIFF format: $utm\n";
print "output DEM: $dem\n";
print "output DEM parameter file: $dem_par\n";
print "log file: $log\n";

$gdal_output = `gdalinfo $utm`;
print $gdal_output;

my @gdal = split /\n/, $gdal_output; #split into lines
foreach my $line (@gdal){

  if ($line =~ m/Size is/) {
    @a = split (/[\s+,]/, $line);	#parse line into tokens, splitting on whitespace or ,
    $xsize = $a[2];
    $ysize = $a[4];
    print "\nDEM samples across: $xsize   down: $ysize\n";
  }

  if ($line =~ m/Upper Left/) {
    @a = split (/[(),]/, $line);	#parse line into tokens, splitting on (),
    $east = $a[1];
    $north = $a[2];
    $lon = $a[4];
    $lat = $a[5];
    print "Upper Left corner easting (m): $east    northing (m):    $north\n";
    print "Upper Left corner lon (deg.):  $lon     latitude (deg.): $lat\n";
    @tok = split((/[d'"]/,$lat));
#    print "latitude tokens: $tok[0], $tok[1], $tok[2], $tok[3]\n";
    $hemi = $tok[3];
  }

  if ($line =~ m/Pixel Size/){
    @a = split (/[(),]/, $line);	#parse line into tokens, splitting on (),
    $pix_east = $a[1];
    $pix_north = $a[2];
    print "Pixel Size (m) easting: $pix_east    northing $pix_north\n";
  }

  if ($line =~ m/central_meridian/){
    @a = split (/[(),]/, $line);	#parse line into tokens, splitting on (),
    $meridian = $a[1];
    print "central meridian: $meridian\n";
    if ($meridian < 0.0) {
      $meridian += 180.0;
    }
    $zone = ceil($meridian/6.0);
    $false_northing = 0.0;

    if ($hemi eq "S") {
      $zone = -$zone;
      $false_northing = 10000000.0
    }


# UTM zone is negative in the southern hemisphere
    print "UTM zone central meridian (deg): $meridian   UTM zone: $zone    false_northing: $false_northing\n";
  }
}

open(DPAR, "> $dem_par_in") or die "ERROR $0: cannot create file with inputs to create_dem_par: $dem_par_in\n\n";
print DPAR "UTM\nWGS84\n1\n$zone\n$false_northing\n$s1\nINTEGER*2\n0.0\n1.0\n$xsize\n$ysize\n$pix_north $pix_east\n$north $east\n";
close(DPAR);
print "\n";
execute("rm -f $dem_par",$log);
execute("create_dem_par $dem_par < $dem_par_in",$log);
print "\n\n";

execute("gdal_translate -ot Int16 -of ENVI $utm $utm_tmp",$log);
execute("swap_bytes $utm_tmp $dem 2", $log);
execute("replace_values $dem 0 -1 $utm_tmp $xsize 0 4", $log);
execute("replace_values $utm_tmp -32768 -1 $dem $xsize 0 4",$log);
execute("/bin/rm -f $utm_tmp",$log);
exit(0);

sub execute{
  my ($command, $log) = @_;
  if (-e $log){open(LOG,">>$log") or die "ERROR $0: cannot open log file: $log  command: $command\n";}
  else {open(LOG,">$log") or die "ERROR $0 : cannot open log file: $log  command: $command\n";}
  LOG->autoflush;
  print "$command\n";
  print LOG ("\n${command}\n");
  close LOG;
  $exit = system("$command 1>> $log");
  $exit == 0 or die "ERROR $0: non-zero exit status: $command\n"
}
