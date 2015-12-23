;# getopts.pl - a better getopt.pl

;# Usage:
;#      do Getopts('a:bc');  # -a takes arg. -b & -c not. Sets opt_* as a
;#                           #  side effect.
;# $opt_err set nonzero in case of error.

sub Getopts {
    local($optlist) = @_;
    local(@args, $_, $first, $rest);
    local($errs) = 0;
    local($[) = 0;
    local(@new_argv, @unused_argv);
    local(@active_argv) = ();

    # Gather up the argv's that we should be examining
    for (;;) {
      last if !@ARGV;
      $each = shift(@ARGV);
      last if ($each eq "--"); # POSIX convention
      push(@active_argv, $each);
      }
    @unused_argv = @ARGV;	# remaining args unprocessed
    @new_argv = ();

    $opt_err = 0;
    @args = split(/ */, $optlist);
    for (;;) { # process argv
      last if !@active_argv;

      if (!(($_ = $active_argv[0]) =~ /^-(.)(.*)/)) {
	# Allow non-switch args, as in gnu getopt
	push(@new_argv, $active_argv[0]);
	shift(@active_argv);
	next;
	}
      ($first,$rest) = ($1,$2);

      $pos = index($optlist, $first);
      if ($pos < $[) {
	print STDERR "Unknown option: $first\n";
	++$opt_err;
	if($rest ne '') {
	  $active_argv[0] = "-$rest";
	  }
	else {
	  shift(@active_argv);
	  }
	next;
	}

      if ($args[$pos + 1] ne ':') { # simple switch argument
	eval "\$opt_$first = 1";
	if ($rest eq '') {
	  shift(@active_argv);
	  }
	else {
	  $active_argv[0] = "-$rest";
	  }
	next;
	}

      # switch takes argument
      if ($rest ne '') {
	eval "\$opt_$first = \"$rest\"";
	shift(@active_argv);
	next;
	}

      shift(@active_argv);
      if ($rest eq '') { # argument is $active_argv[0]
	if (!@active_argv) {
	  print STDERR "-$first:  argument missing\n";
	  $opt_err ++;
	  last;
	  }
	$rest = shift(@active_argv);
	if ($rest eq "--") {
	  print STDERR "-$first:  argument missing\n";
	  $opt_err ++;
	  last;
	  }
	} # argument is $active_argv[0]
      eval "\$opt_$first = \$rest;";
    } # process argv

    # Remaining args are left for caller...
    @ARGV = (@new_argv, @unused_argv);;
}

1;

