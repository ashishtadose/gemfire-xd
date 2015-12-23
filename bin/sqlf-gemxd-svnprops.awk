# on a linux bash, invoke following to generate cmds copying svn: properties.
#
#  bash>  svn pl . -R | awk -f /home/soubhikc/sqlf-gemxd-svnprops.awk | less
#
# having saved the commands in a file, to execute use the following.
#
#  bash>  cat DDDD | awk '/svn/,/^END/' | xargs -d\; -i{} bash -c {}
#
# to revert a particular property following command needs to be scripted
# bash>  svn ps svn:ignore "$(svn pg svn:ignore -r HEAD)" . 
#
/Properties on / {
  match($0, "'.*':");
  file=substr($0, RSTART + 1, RLENGTH - 3);
  numfiles++;
  next;
}

!/(eol-style|svn:executable|svn-executable|svn:mime-type)/ {
   prop=$0;
   tgtfile=transform(file);
   q="svn pg "prop" "tgtfile;
   delete tgtprops;
   while ( ( q | getline l) > 0) {
      l=trim(l);
      if(length(l) <= 0 || l=="." || l=="true") {
        continue;
      }
      tgtprops[prop""l]++;
   }
   close(q);

   cmd="svn ps "trim(prop)" -F /dev/fd/0 "tgtfile" << END\n";
   
   q="svn pg "prop" "file;
   pvals="";
   while ( (q | getline l) > 0) {
      l=trim(l);
      if(length(l) <= 0 || l=="." || l=="true" || tgtprops[prop""l] > 0) {
        continue;
      }
      pvals=pvals""l"\n";
   }
   close(q);

   if (length(pvals) <= 0) {
     next;
   }
   cmd=cmd""pvals"END\n;";
   print cmd"\n";
   
}

 function trim(str) {
   gsub(/[ \t]*/,"",str);
   return str;
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
