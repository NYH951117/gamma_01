#!/usr/bin/perl
use FileHandle;
use File::Basename;
$log = "geo2float.log";

if (($#ARGV + 1) < 3){die <<EOS ;}
*** $0
*** Copyright 2014, Gamma Remote Sensing, v1.0 1-May-2014 clw ***
*** Convert Float32 GeoTiff data in geographic coordinates (EQA) to binary (big endian float)  and Gamma DEM parameter file ***

usage: $0 <geo_data> <data> <DEM_par>
    geo_data  (input)  input GeoTIFF file (Float32) in geographic coordinates (EQA)
    data      (output) image data (Float32)
    DEM_par   (output) Gamma DEM parameter file

EOS

$geo = $ARGV[0];
$data     = $ARGV[1];
$dem_par = $ARGV[2];
$dem_par_in = "dem_par.in";
$geo_tmp= "geo_tmp";
my ($s1, $dir1, $ext1) = fileparse($geo, qr/\.[^.]*/); #extension is the last bit after the last period
print "basename: $s1\n";

print "Float data geographic voordiantes (EQA) GeoTIFF format: $geo\n";
print "output data: $data\n";
print "output DEM parameter file: $dem_par\n";
print "log file: $log\n";

$gdal_output = `gdalinfo $geo`;
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
    $lon = $a[1];
    $lat = $a[2];
    print "Upper Left corner latitude (deg.): $lat    longitude (deg.): $lon\n";
  }

  if ($line =~ m/Pixel Size/){
    @a = split (/[(),]/, $line);	#parse line into tokens, splitting on (),
    $pix_lon = $a[1];
    $pix_lat = $a[2];
    print "Pixel Size (deg.) latitude: $pix_lat    longitude: $pix_lon\n";
  }
}

#correct for Pixel as Area
printf "DEM (Pixel as Area) upper left corner latitude (deg.): $lat  longitude (deg.): $lon\n"; 
$lat = $lat + $pix_lat/2.0;
$lon = $lon - $pix_lat/2.0;
printf "DEM (Pixel as Point) upper left corner latitude (deg.): $lat  longitude (deg.): $lon\n";

open(DPAR, "> $dem_par_in") or die "ERROR $0: cannot create file with inputs to create_dem_par: $dem_par_in\n\n";
print DPAR "\nEQA\nWGS84\n1\n$s1\nREAL*4\n0.0\n1.0\n$xsize\n$ysize\n$pix_lat $pix_lon\n$lat $lon\n";
close(DPAR);
print "\n";
execute("rm -f $dem_par",$log);
execute("create_dem_par $dem_par < $dem_par_in",$log);
print "\n\n";

execute("gdal_translate -ot Float32 -of ENVI $geo $geo_tmp",$log);
execute("swap_bytes $geo_tmp $data 4", $log);
execute("/bin/rm -f $geo_tmp",$log);
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
