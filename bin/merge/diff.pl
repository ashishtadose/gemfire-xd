#! /bin/perl -w
#-------------
# Compare the file lists between two directories.  This is a sanity
# check after a branch upmerge since SVN is not reliable.  In theory you
# should have the same files in both directories, right?
#
# Output is a list of files that are different between the two directory
# trees.  Things like files not under SVN control and files that differ
# in content are flagged for review.
#
# No small animals (files) were harmed (modified) by this script.
#-------------

my($branch) = "/export/shared_build/users/jpenney/prFeb07";
my($trunk) = "/export/shared_build/users/jpenney/upmerge";

my(@new_in_branch, @new_in_trunk);
my(@common);

&collate_files($branch, $trunk);

# Scrutinize the new files
my($each);
foreach $each (@new_in_branch) {
  if (!&is_svn("$branch/$each")) {
    print "Unversioned on branch: $each\n";
    next;
    }
  print "File under svn on branch but not trunk: $each\n";
  }
foreach $each (@new_in_trunk) {
  if (!&is_svn("$trunk/$each")) {
    print "Unversioned on trunk: $each\n";
    next;
    }
  print "File under svn on trunk but not branch: $each\n";
  }

# Scrutinize the common files
foreach $each (@common) {
  next if !&is_svn("$trunk/$each") && !&is_svn("$branch/$each");
  next if &filesEqual("$trunk/$each", "$branch/$each");
  print "Files differ: $each\n";
  }

exit 0;

# -------
# Return 1 if the two files are equal
# -------
sub filesEqual {
  my($f1, $f2) = @_;

  return 1 if -d $f1 && -d $f2;
  if (-d $f1 || -d $f2) {
    print "Dir/Nondir difference: $f1 $f2\n";
    return 0;
    }

  my($status) = system "diff -q $f1 $f2 >/dev/null";
  return 1 if $status == 0;
  if ($status >= 0x80) {
    $status >>= 8;
    return 0 if $status == 1;
    }
  die "diff of $f1 and $f2 failed with abnormal status $status";
  }

# -------
# Return 1 if this file has an SVN shadow
# -------
sub is_svn {
  my($name) = @_;
  my($dirname, $basename);

  $dirname = $name;
  if ($dirname !~ m#/#) {
    $dirname = ".";
    $basename = $name;
    }
  else {
    $name =~ m#(.*)/([^/]+)#;
    $dirname = $1;
    $basename = $2;
    }

  return 0 if !defined($basename);
  if (-f "$dirname/.svn/text-base/$basename.svn-base") {
    return 1;
    }
  return 0;
  }

# -------
# Collate all file names into the three
# groups @new_in_branch, @new_in_trunk, and @common
# -------
sub collate_files {
  my($branch, $trunk) = @_;
  my(@all_in_branch) = &harvest_names($branch);
  my(@all_in_trunk) = &harvest_names($trunk);

  my(%hbranch, %htrunk);
  my($each);
  foreach $each (@all_in_branch) {
    $hbranch{$each} = 1;
    }
  foreach $each (@all_in_trunk) {
    $htrunk{$each} = 1;
    }

  foreach $each (@all_in_branch) {
    if (defined($htrunk{$each}) ){
      push @common, $each;
      next;
      }
    push @new_in_branch, $each;
    }
  foreach $each (@all_in_trunk) {
    if (!defined($hbranch{$each}) ){
      push @new_in_trunk, $each;
      }
    }
  }

# -------
# Recursively harvest all of the names in a directory tree
# The base name is not prepended, but everything _after_ it is returned.
# -------
sub harvest_names {
  my($base) = @_;
  my(@result);
  my(@dirs);

  my(@names) = &get_files($base);
  my($each);
  foreach $each (@names) {
    if (-d "$base/$each") {
      push @dirs, $each;
      next;
      }
    push @result, $each;
    }

  foreach $each (@dirs) {
    my(@subnames) = &harvest_names("$base/$each");
    my($eachname);
    foreach $eachname (@subnames) {
      push @result, "$each/$eachname";
      }
    }
  return @result;
  }

# -------
# Return the filenames in a given directory, omitting the obvious
# ones (., .., and .svn)
#
# No type of directory name is prepended.
# -------
sub get_files {
  my($base) = @_;
  my(@names);

  opendir(F, $base) || die "opendir $base: $!";
  @names = readdir(F);
  closedir(F);

  my($each);
  my(@result);
  foreach $each (@names) {
    next if $each eq ".";
    next if $each eq "..";
    next if $each eq ".svn";
    next if $each eq ".glimpse";
    next if $each eq ".metadata";
    next if $each eq ".classpath";
    next if $each eq ".project";
    push @result, $each;
    }
  return(@result);
  }
