#!/usr/bin/perl
use FileHandle;
use File::Basename;

if (($#ARGV + 1) < 3){die <<EOS ;}
*** $0
*** Copyright 2015, Gamma Remote Sensing, v1.1 28-Apr-2015 clw ***
*** Copy selected SLCs from a directory to an output directory skipping by a specified step ***

usage: $0 <dir> <mv_dir> <step> <xoff> <nx> <yoff> <ny> <dtab_out>
    dir       (input) directory containing input SLC data
    mv_dir    directory for the output SLC data
    step      SLCs are moved from the input directory skipping by step
EOS

print "list of input directories containing SLCs: $ARGV[0]\n";
$dir    = $ARGV[0];
$mv_dir = $ARGV[1];
$step   = $ARGV[2];
 
unless (-d $mv_dir) {
  (mkdir $mv_dir) or die "ERROR $0: non-zero exit status, could not create output directory $mv_dir\n"
}

print "output directory: $mv_dir\n";
print "step between SLCs: $step\n";

$log = "$mv_dir/mv_slc.log"; 
open(LOG,">$log") or die "ERROR $0: cannot open log file: $log\n\n";

@slcs = glob($dir."/*.slc");  #get directory list
printf "\ndirectory: $dir   number of SLCs: %d\n",scalar @slcs;
for ($i = 0; $i < (scalar @slcs); $i += $step){
  $slc = $slcs[$i];
  $slc_par = $slc.".par";
  if (-e $slc_par) {
    execute("mv $slc $slc_par $mv_dir",$log);
  }
}

$time = localtime;
open(LOG,">>$log") or die "ERROR $0: cannot open log file: $log\n\n";
print LOG "\n*** $0 processing end: $time ***\n";
print "\n*** $0 processing end: $time ***\n";
exit 0;

sub execute{
  my ($command, $log) = @_;  
  if (-e $log){open(LOG,">>$log") or die "\nERROR $0: cannot open existing log file: $log\n";}
  else {open(LOG,">$log") or die "\nERROR $0: cannot open new log file: $log\n";} 
  LOG->autoflush; 
  print "$command\n";
  print LOG ("\n${command}\n");
  close LOG;  
  $exit = system("$command 1>> $log");
  $exit == 0 or die "ERROR $0: non-zero exit status: $command\n"
}

