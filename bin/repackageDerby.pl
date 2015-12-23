#!/usr/bin/perl
#Use this line for profiling
#!/usr/bin/perl -d:DProf

use strict;
use Cwd;
use Config;

use File::Find;
use File::Path;
use File::Basename;
use FileHandle;
#Should use our, but lame 5.0 perl doesnt have it.
use vars qw($osbuilddir $length);
my $dir = $ARGV[0];
$osbuilddir = $ARGV[1];

my $curr = cwd();
if ($Config{osname} =~ /win/i && $Config{osname} !~ /Darwin/i ) {
  $curr = `cygpath -w $curr`;
}
$length = split(//,$curr) + 1;

find(\&process, $dir);

sub process() {

  my $file = $File::Find::name;
  my $old_dir = dirname($file);
  my $new_file = basename($file);
  my $new_dir = $old_dir;
  $new_dir = (split(//, $new_dir, $length))[-1];
  $new_dir =~ s#org/apache/derby(?!\w)#com/pivotal/gemfirexd/internal#;
  $new_dir = $osbuilddir . "/" . $new_dir;
  my $new_file = $new_dir . "/" . basename($file);
  if ( -f $new_file ) {
    my($a, $b, $c, $d, $e, $f, $g, $h, $old_time) = lstat($file); 
    my($i, $j, $k, $l, $m, $n, $o, $p, $new_time) = lstat($new_file); 
    if( $old_time <= $new_time ) {
      return;
    }
  } 
  return unless -f $file;
  return if($file =~ /\.svn/);
  mkpath( $new_dir ) if ( ! -d $new_dir );
  my $fp_in  = new FileHandle($file) 
    || die "couldn't open $file\n";
  my $fp_out = new FileHandle($new_file, "w") 
    || die "couldn't open $new_file\n";
  my @lines = $fp_in->getlines();
  foreach my $line (@lines) {
    $line =~ s/org(\.|\/)apache(\.|\/)derby(?=\W)/com\1vmware\1gemfirexd\1internal/g;
    $fp_out->print($line);
  }

  $fp_in->close(); 
  $fp_out->close(); 
}

