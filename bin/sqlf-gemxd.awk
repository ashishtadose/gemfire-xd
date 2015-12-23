BEGIN {FS = "|"}
{
# derive the new file name
  str = $1;
  gsub(/com\/vmware\/sqlfire/,"com/pivotal/gemfirexd", str);
  str = transform(str);

  print "svn rename --parents " $1 " " str;

  if ($1 ~ /\.java/) {
# change the package name & then replace
    str2 = $1;
    str2 = gensub(/.*(com\/vmware.*$)/,"\\1", "g", str2);
    gsub(/\//, ".", str2);
    gsub(/\.java/, "", str2);

    str3 = str;
    str3 = gensub(/.*(com\/pivotal.*$)/,"\\1", "g", str3);
    gsub(/\//, ".", str3);
    gsub(/\.java/, "", str3);

    str3 = transform(str3);
# (lets do it in one shot later. otherwise takes a long time)   print "perl -e \"s/" str2 "/" str3 "/g\" -pi $( find . ! -wholename \"*.svn*\"  ! -name \"open_source_licenses.txt*\" ! -wholename \"*AdoNetTest.WIN*\" -type f)";

# now stip away the package name & only replace classname 
    n=split(str2, sar2, ".");
    str4 = sar2[n];

    n=split(str3, sar3, ".");
    str5 = sar3[n];

    if (str4 != str5) {
      print "perl -e \"s/" str4 "/" str5 "/g\" -pi $( find . ! -wholename \"*.svn*\"  ! -name \"open_source_licenses.txt*\" ! -wholename \"*AdoNetTest.WIN*\" -type f)";
    }
  }
  else {
    if ($1 ~ /\/.*\.conf|\/.*\.inc|\/.*\.bt|\/.*\.cpp|\/.*\.h|\/.*\.cs|\/.*\.c/) {
      str2=$1;
      z=split(str2, tstr, "/");
      str2 = tstr[z];
      gsub(/\..*/, "", str2);
      str3=transform(str2);
      if (str2 != str3) {
        print "perl -e \"s/" str2 "/" str3 "/g\" -pi $( find . ! -wholename \"*.svn*\"  ! -name \"open_source_licenses.txt*\" ! -wholename \"*AdoNetTest.WIN*\" -type f)";
      }
    }
  }

  print " ";
  print " ";
}

 function transform(str)
 {
   gsub(/SQLFire/,"GemFireXD", str);
   gsub(/Sqlfire/,"Gemfirexd", str);
   gsub(/SQLF/,"GFXD", str);
   gsub(/Sqlf/,"Gfxd", str);
   gsub(/SqlFire/,"GemFireXD", str);
   gsub(/SqlF/,"GFXD", str);
   gsub(/sqlfire/,"gemfirexd", str);
   gsub(/sqlf/,"gfxd", str);

   gsub(/vmware/,"pivotal", str);
   return str;
 }
