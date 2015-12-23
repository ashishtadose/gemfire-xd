#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - partnummapping.pl
#
# Purpose - support for maketape, makekey, makecdimage, release
#           to convert from a partnumber to directory names
#
#=========================================================================

# Map from architecture to a category of filenames.  Put here
# to be generally available
%ArchExtensions =  (
    "all.unix", "unix",
    "all.windows", "dos",
    "all", "unix",
    "sparc.SunOS4", "unix",
    "sparc.Solaris", "unix",
    "hppa.hpux", "unix",
    "hppa.hpux_8", "unix",
    "hppa.hpux_9", "unix",
    "Symmetry.Dynix", "unix",
    "i386.NCR", "unix",
    "MIPSEB.sinix", "unix",
    "RISC6000.AIX", "unix",
    "x86.Windows_NT", "dos",
    "x86.Windows_95", "dos",
    "x86.NTWindows_95", "dos",
    "x86.os2", "dos",
    "x86.win31", "dos",
    "x86.win32s", "dos",
    "x86.NTWin32s", "dos",
    "i686.Linux", "unix",
    "mac", "mac",
    "powermac", "mac" );

# These associations map portions of partnumbers to text strings
# used for parts of directory names.
# The CDRom versions must be 8 characters or less, use numbers or
# capital letters, and must use "_" (underscore)
# instead of "." (period or dot).  In short, a DOS directory name.

# Map the 1st field in a partnumber to a long product name
# for the ship inventory directory, for tar tapes, distribution via web,
# and distribution via CDRom.
# For the source code demarcation, use Field #1 of the real product
# and add 100 to # that field and add "Src" to each of the product names.
# So, the Object Server source code would be Item No. 101, the GemBuilder
# source code would be 102, the GemStone DataBridge is 140, etc.
# This array is used to get directory names or parts of directory names
# for tar tapes, distribution via web, and distribution via CDRom.
# If you add a product, put in a name for all three!

# If you add a product type, also add a product-source type!
$prodStrMapWidth = 6;   # five elements per row
@prodStrMapping = (
# Num    Name for               Name for                Short Name     Name for Prodrev                       Can Be
#          tar                     Web                   for CDRom      sign off sheets                      Exported
  "1", "GemStone",              "GemStone",              "GEMSTONE", "GemStone Object Server",                   1,
  "2", "GemBuilder",            "GemBuilder",            "GBS",      "GemBuilder for Smalltalk",                 1,
  "4", "GemAccessODBC",         "GemAccessODBC",         "GAODBC",   "GemAccess for ODBC",                       1,
  "5", "GemORB",                "GemORB",                "GEMORB",   "GemORB",                                   1,
# These next 4 GemStoneJ*Edition are really just links to Num 12 GemStoneJ.  Diff name, same product.
  "6", "GemStoneJWebEdition",   "GemStoneJWebEdition",   "GSJ",      "GemStone/J Web Edition",                   1,
  "7", "GemStoneJComponentEdition","GemStoneJComponentEdition","GSJ","GemStone/J Component Edition",             1,
  "8", "GemStoneJEnterpriseEdition","GemStoneJEnterpriseEdition","GSJ","GemStone/J Enterprise Edition",          1,
  "9", "GemFirePJ",       "GemFirePJ",       	 "PUREJAVA",  "GemStone GemFire PureJava Installer",           1,
 "10", "OldGemFire",       	"OldGemFire",    "OLDGEMFIRE",   "OLDGemStone GemFire Installer",           1,
 "12", "GemStoneJ",             "GemStoneJ",             "GSJ",      "GemStone/J",                               1,
 "13", "GemFire",       	"GemFire",       	 "GEMFIRE",      "GemStone GemFire Installer",           1,
 "14", "GemFireRTE",       	"GemFireRTE",       	 "GFRTE",      "GemStone GemFireRTE Installer",           1,
 "15", "GemBuilderJV",          "GemBuilderJV",          "GBJ",      "GemBuilder for Java",                      1,
 "16", "GemFireC++",       	"GemFireC++",       	 "GFCPP",      "GemStone GemFire Enterprise C++ Installer",           1,
 "17", "GemFireDBA",            "GemFireDBA",            "GFDBA",      "GemStone GemFire DB Accelerator Installer",           1,
 "018", "GemStoneFacets",       "GemStone Facets",       "GSFACETS",      "GemStone Facets Installer",           1,
 "20", "GemBuilderC",           "GemBuilderC",           "GBC",      "GemBuilder for C",                         1,
 "21", "Codemesh_C++_GFE",      "GFECodemeshC++",        "GFECMCPP", "Codemesh C++ Module for GemFire",          1,
 "22", "Codemesh_C#_GFE",       "GFECodemeshC#",         "GFECMC#",  "Codemesh CSharp Module for GemFire",            1,
 "23", "Codemesh_C++_RTE",      "RTECodemeshC++",        "RTECMCPP", "Codemesh C++ Module for RTE",          1,
 "24", "Codemesh_C#_RTE",       "RTECodemeshC#",         "RTECMC#",  "Codemesh CSharp Module for RTE",            1,
 "28", "NativeClientCSHARP",    "GemFireNativeClientCSHARP", "GFNCCS",   "NativeClient C# Module for GemFire",       1,
 "29", "NativeClientC++",       "GemFireNativeClientC++","GFNCCPP",  "NativeClient C++ Module for GemFire",      1,
 "30", "GemEnterprise",         "GemEnterprise",         "GEMENT",   "GemEnterprise",                            1,
 "40", "GemStoneDataBridge",    "GemStoneDataBridge",    "DATABRDG", "GemStone DataBridge",                      1,
 "41", "GemConnect",            "GemConnect",            "GEMCONN",  "GemConnect",                               1,
 "50", "GemBuilderC++",         "GemBuilderC++",         "GBCPP",    "GemBuilder for C++",                       1,
 "60", "GSJSSLEncryption",      "GSJSSLEncryption",      "GSJSSL",   "GemStone/J SSL Encryption, Domestic Only", 0,
 "61", "GSJSSLInternationalEncryption","GSJSSLInternationalEncryption","GSJSSLIN", "GemStone/J SSL International Encryption",  1,
 "62", "RSAEncryption",         "RSAEncryption",         "RSA",      "RSA Encryption, Domestic Only",            0,
 "63", "RSAInternationalEncryption","RSAInternationalEncryption","RSAINT", "RSA International Encryption",       1,
 "64", "JCE",                   "JCE",                   "JCE",      "Java Cryptography Extension",              0,
 "70", "GSJTCCPlugin",          "GSJTCCPlugin",          "GSJTCC",   "GSJ TCC Plug-in",                          1,
 "80", "GeODE",                 "GeODE",                 "GEODE",    "GeODE",                                    1,
 "85", "GeODEXlibs",            "GeODEXlibs",            "GEODEXLB", "GeODE X libraries",                        1,
 "87", "GSSUpdate",             "GSSUpdate",             "GSSUPDAT", "GemStone/S Update",                        1,
 "88", "GSJUpdate",             "GSJUpdate",             "GSJUPDAT", "GemStone/J Update",                        1,
 "89", "GSJConversionKit",      "GSJConversionKit",      "GSJCONV",  "GemStone/J conversion kit",                1,
 "90", "Demo",                  "Demo",                  "DEMO",     "Demo",                                     1,
 "91", "GSJDemo",               "GSJDemo",               "GSJDEMO",  "GSJDemo",                                  1,
 "92", "GemBuilderDemo",        "GemBuilderDemo",        "GBSDEMO",  "GemBuilder demo",                          1,
 "93", "GuidedTour",            "GuidedTour",            "TOUR",     "Guided Tour",                              1,
 "95", "GBJGBWDemo",            "GBJGBWDemo",            "GBJWDEMO", "GBJ/GBW demo",                             1,
 "99", "BetaSoftware",          "BetaSoftware",          "BETASW",   "Beta Software",                            1,
"100", "GSConversionKit",       "GSConversionKit",       "GSCONV",   "GemStone conversion kit",                  1,
"101", "GemStoneSrc",           "GemStoneSrc",           "GSSRC",    "GemStone Object Server Sources",           1,
"102", "GemBuilderSrc",         "GemBuilderSrc",         "GBSSRC",   "GemBuilder for Smalltalk Sources",         1,
"104", "GemAccessODBCSrc",      "GemAccessODBCSrc",      "GODBCSRC", "GemAccess for ODBC Sources",               1,
"105", "GemORBSrc",             "GemORBSrc",             "GMORBSRC", "GemORB Sources",                           1,
"109", "GemFirePJSrc",       	"GemFirePJSrc",       	 "GFPJSRC",  "GemStone GemFire PureJava Sources",        1,
"110", "GemFireSrc",       	"GemFireSrc",       	 "GFIRESRC",      "GemStone GemFire Sources",            1,
"112", "GemStoneJSrc",          "GemStoneJSrc",          "GSJSRC",   "GemStone/J Sources",                       1,
"113", "GemFireSrc",       	"GemFireSrc",       	 "GFIRESRC",      "GemStone GemFire Sources",            1,
"114", "GemFireRTESrc",       	"GemFireRTESrc",       	 "GFRTESRC",      "GemStone GemFireRTE Sources",         1,
"115", "GemBuilderJVSrc",       "GemBuilderJVSrc",       "GBJSRC",   "GemBuilder for Java Sources",              1,
"116", "GemFireC++Src",       	"GemFireC++Src",       	 "GFCPPSRC", "GemStone GemFire Enterprise C++ Sources",  1,
 "117", "GemFireDBASrc",        "GemFireDBASrc",         "GFDBASRC", "GemStone GemFireDBA Sources",              1,
"117", "GemBuilderWebSrc",      "GemBuilderWebSrc",      "GBWSRC",   "GemBuilder for the Web Sources",           1,
"118", "GemStoneFacetsSrc",     "GemStoneFacetsSrc",     "GSFSRC",   "GemStone Facets Sources",                  1,
"120", "GemBuilderCSrc",        "GemBuilderCSrc",        "GBCSRC",   "GemBuilder for C Sources",                 1,
"121", "Codemesh_C++_GFE_Src",  "GFECMC++SRC",           "GFECMSRC", "Codemesh C++ for GemFire Sources",         1,
"122", "Codemesh_C#_GFE_Src",   "GFECMCSSRC",            "GFECMC#",  "Codemesh CSharp for GemFire Sources",      1,
"123", "Codemesh_C++_RTE_Src",  "RTECMC++SRC",           "RTECMCPP", "Codemesh C++ for RTE Sources",             1,
"124", "Codemesh_C#_RTE_Src",   "RTECMCSSRC",            "RTECMC#",  "Codemesh CSharp for RTE Sources",          1,
"128", "NativeClientCSHARP_Src",    "GemFireNativeClientCSHARPSRC", "GFNCCS",   "NativeClient C# Module for GemFire Sources",      1,
"129", "NativeClientC++_Src",   "GemFireNativeClientC++SRC","GFNCCPP",  "NativeClient C++ Module for GemFire Sources",     1,
"130", "GemEnterpriseSrc",      "GemEnterpriseSrc",      "GENTSRC",  "GemEnterprise Sources",                    1,
"140", "GemStoneDataBridgeSrc", "GemStoneDataBridgeSrc", "DTBRSRC",  "GemStone DataBridge Sources",              1,
"141", "GemConnectSrc",         "GemConnectSrc",         "GCONNSRC", "GemConnect Sources",                       1,
"150", "GemBuilderC++Src",      "GemBuilderC++Src",      "GBCPPSRC", "GemBuilder for C++ Sources",               1,
"160", "GSJSSLEncryptionSrc",   "GSJSSLEncryptionSrc",   "GJSSLSRC", "GemStone/J SSL Encryption Sources, Domestic Only", 0,
"161", "GSJSSLInternationalEncryptionSrc","GSJSSLInternationalEncryptionSrc","GJSLISRC", "GemStone/J SSL International Encryption Sources", 0,
"162", "RSAEncryptionSrc",      "RSAEncryptionSrc",      "RSASRC",   "RSA Encryption Sources, Domestic Only",    0,
"163", "RSAInternationalEncryptionSrc","RSAInternationalEncryptionSrc","RSAISRC", "RSA International Encryption Sources", 0,
"164", "JCESrc",                "JCESrc",                "JCESRC",   "Java Cryptography Extension Sources",      0,
"170", "GSJTCCPluginSrc",       "GSJTCCPluginSrc",       "GSJTCSRC", "GSJ TCC Plugin Sources",                   1,
"180", "GeODESrc",              "GeODESrc",              "GEODESRC", "GeODE Sources",                            1,
"185", "GeODEXlibsSrc",         "GeODEXlibsSrc",         "GDXLBSRC", "GeODE X libraries Sources",                1,
"187", "GSSUpdateSrc",          "GSSUpdateSrc",          "GSSUPSRC", "GemStone/S Update Sources",                1,
"188", "GSJUpdateSrc",          "GSJUpdateSrc",          "GSJUPSRC", "GemStone/J Update Sources",                1,
"189", "GSJConversionKitSrc",   "GSJConversionKitSrc",   "GSJCVSRC",  "GemStone/J conversion kit Sources",       1,
"190", "DemoSrc",               "DemoSrc",               "DEMOSRC",  "Demo Sources",                             1,
"191", "GSJDemoSrc",            "GSJDemoSrc",            "GSJDMSRC", "GSJDemoSrc",                               1,
"192", "GemBuilderDemoSrc",     "GemBuilderDemoSrc",     "GBDMOSRC", "GemBuilder demo Sources",                  1,
"193", "GuidedTourSrc",         "GuidedTourSrc",         "TOURSRC",  "Guided Tour",                              1,
"195", "GBJGBWDemoSrc",         "GBJGBWDemoSrc",         "GBJWDSRC", "GBJ/GBW demo Sources",                     1,
"199", "BetaSoftwareSrc",       "BetaSoftwareSrc",       "BETASRC",  "Beta Software Sources",                    1,
"200", "DocMaster",             "DocMaster",             "DOCS",     "GemStone/J Documentation Master files",    1,
"201", "GSJDocs",               "GSJDocs",               "GSJDOCS",  "GemStone/J Documentation files",    1,
"202", "InstallGuides",         "InstallGuides",         "INSGUIDE", "GemStone/J Install Guides",    1,
"203", "GSJPDF",                "GSJPDF",                "GSJPDF",   "GemStone/J Documentation files (PDF version)",    1,
"204", "JSrvDocs",              "JSrvDocs",              "JSRVDOCS", "JServer Documentation files",    1,
"205", "InstallGuide",         "InstallGuide",         "INSGUIDE", "GemStone Facets Install Guide PDF",    1,
"206", "GSFPDF",                "GSFPDF",                "MANUALS",   "GemStone Facets Documentation files PDF",    1,
"250", "DocMasterSpc",          "DocMasterSpc",          "DOCSPC",   "GemStone/J Documentation Master special files", 1,
"251", "GSJDocsSpc",            "GSJDocsSpc",            "GSJDSPC",  "GemStone/J Documentation files special files",  1,
"252", "InstallGuidesSpc",      "InstallGuidesSpc",      "INSGDSPC", "GemStone/J Install Guides special files",       1,
"253", "GSJPDFSpc",             "GSJPDFSpc",             "GSJPSPC",  "GemStone/J Documentation files (PDF version) special files",  1,
"254", "JSrvDocsSpc",           "JSrvDocsSpc",           "JSRVDSPC", "JServer Documentation files special files",    1,
"301", "GemStoneCopyright",     "GemStoneCopyright",     "GSCPYRT",  "GemStone Object Server Copyright Registration", 1,
"312", "GemStoneJCopyright",    "GemStoneJCopyright",    "GSJCPYRT", "GemStone/J Server Copyright Registration",      1,
"314", "GemStoneJVisiBrokerCopyright", "GemStoneJVisiBrokerCopyright", "GSJCPYRT", "GemStone/J with VisiBroker ORB Copyright Registration",1,
"400", "OracleThinJDBCDriver",  "OracleThinJDBCDriver",     "ORACJDBC", "Oracle Thin JDBC Driver",                    1,
"402", "SequeLinkJDBCDriver",   "SequeLinkJDBCDriver",       "SEQJDBC", "DataDirect SequeLink",                       1,
"403", "SequeLinkJDBCDriverEncrption","SequeLinkJDBCDriverEncription","SEQJDBCE", "DataDirect SequeLink with Encryption", 1,
"404", "SybasejConnectJDBCDriver","SybasejConnectJDBCDriver","SYBJDBC", "Sybase jConnect JDBC Driver",                1,
"406", "SequeLinkDB2MVSDriver", "SequeLinkDB2MVSDriver",     "SEQDB2",  "DataDirect SequeLink for DB2/MVS",           1,
"408", "VerveWorkflow",         "VerveWorkflow",         "VERVEWRK", "Verve Component Workflow Engine",           1,
"450", "OracleThinJDBCDriverSpc",    "OracleThinJDBCDriverSpc",    "ORCJDSPC", "Oracle Thin JDBC Driver special files",          1,
"452", "SequeLinkJDBCDriverSpc",     "SequeLinkJDBCDriverSpc",     "SEQJDSPC", "DataDirect SequeLink special files",             1,
"453", "SequeLinkJDBCDriverEncrptionSpc","SequeLinkJDBCDriverEncriptionSpc","SEQJESPC", "DataDirect SequeLink with Encryption special files", 1,
"454", "SybasejConnectJDBCDriverSpc","SybasejConnectJDBCDriverSpc","SYJDBSPC", "Sybase jConnect JDBC Driver special files",      1,
"456", "SequeLinkDB2MVSDriverSpc",   "SequeLinkDB2MVSDriverSpc",   "SEQDBSPC", "DataDirect SequeLink for DB2/MVS special files", 1,
"458", "VerveWorkflowSpc",      "VerveWorkflowSpc",      "VRVWKSPC", "Verve Component Workflow Engine special files",           1,
"500", "SourceCodeManagerToolKit", "SourceCodeManagerToolKit", "SRCKIT",  "Source Code Manager Tool Kit",        1,
"510", "GSMaintenanceToolKit",  "GSMaintenanceToolKit",  "GSMNTKIT", "Maintenance Framework for Smalltalk Tool Kit", 1,
"520", "GSPerformanceProfiler", "GSPerformanceProfiler", "GSPERF",   "Performance Profiler for Smalltalk Tool Kit",  1,
"530", "GSJPerformanceProfiler","GSJPerformanceProfiler","GSJPERF",  "Performance Profiler for GS/J Tool Kit",       1,
"541", "GemConnect",            "GemConnect",            "GEMCONN",  "GemConnect Tool Kit",                      1,
"550", "DBAassistant",          "DBAassistant",          "DBAKIT",   "DBA Assistant Tool Kit",                   1,
"600", "SourceCodeManagerToolKitSrc", "SourceCodeManagerToolKitSRC", "SRCKTSRC",  "Source Code Manager Tool Kit Sources", 1,
"610", "GSMaintenanceToolKitSrc",  "GSMaintenanceToolKitSrc",  "MNTKTSRC", "Maintenance Framework for Smalltalk Tool Kit Sources", 1,
"620", "GSPerformanceProfilerSrc", "GSPerformanceProfilerSrc", "GSPRFSRC", "Performance Profiler for Smalltalk Tool Kit Sources",  1,
"630", "GSJPerformanceProfilerSrc","GSJPerformanceProfilerSrc","GSJPFSRC", "Performance Profiler for GS/J Tool Kit Sources",       1,
"641", "GemConnectSrc",            "GemConnectSrc",            "GCONNSRC", "GemConnect Tool Kit Sources",        1,
"650", "DBAassistantSrc",          "DBAassistantSrc",          "DBAKTSRC", "DBA Assistant Tool Kit Sources",     1,
"700", "BrokatAdvServ_isoimage",   "BrokatAdvServ_isoimage",   "BAS", "Brokat Advanced Server ISO Image",      1,
"701", "BrokatEntServ_isoimage",   "BrokatEntServ_isoimage",   "BES", "Brokat Enterprise Server ISO Image",      1,
);


# Map the 2nd field in a partnumber to a long architecture name.
# This array is used to get directory names or parts of directory names
# for tar tapes, distribution via web, and distribution via CDRom.
# For CDRom, use only 8 chars or fewer, use only A-Z, 0-9, _ (underscore).
# If you add a product, put in a name for all three!

$archStrMapWidth = 5;   # five elements per row
@archStrMapping = (
# Number, Name for         Name for        Short Name     Name for Prodrev
#           tar              Web            for CDRom      sign off sheets
  "1", "MIPSEL.Ultrix",    "Ultrix",        "ULTRIX",    "Ultrix",
  "3", "MIPSEB.sinix",     "sinix",         "SINIX",     "sinix",
  "4", "sparc.SunOS4",     "SunOS4",        "SUNOS4",    "SunOS 4.1",
  "5", "i386.NCR",         "NCR",           "NCR",       "NCR",
  "7", "hppa.hpux",        "hpux",          "HPUX",      "HP9000/Series 700 & 800/HPUX 10.10, 10.20",
  "8", "Symmetry.Dynix",   "Dynix",         "DYNIX",     "Dynix",
  "9", "RISC6000.AIX",     "AIX",           "AIX",       "IBM RS6000/AIX 4.1, 4.2",
 "010", "sparc.Solaris",    "Solaris",       "SOLARIS",   "SPARC/Solaris 2.8",
 "011", "x86.Windows_NT",   "NT",            "WIN_NT",    "Windows NT 5.0",
 "12", "x86.Windows_95",   "Win95",         "WIN_95",    "Windows 95",
 "20", "x86.win31",        "win31",         "WIN_31",    "Windows 3.1",
 "25", "x86.win32s",       "win32s",        "WIN_32S",   "Win32s",
 "30", "x86.os2",          "os2",           "OS2",       "OS/2",
 "40", "mac",              "mac",           "MAC",       "Macintosh",
 "41", "powermac",         "powermac",      "POWERMAC",  "PowerMac",
"050", "i686.Linux",       "Linux",         "LINUX",     "Linux",
"100", "all.unix",         "unix",          "ALL_UNIX",  "All Unix Platforms",
"110", "all",              "all",           "ALL",       "All Platforms",
"111", "alljava",          "java",          "PUREJAVA",  "Any Java Platform",
"120", "os2.Windows",      "os2_Windows",   "OS2_WIN",   "OS/2 and Windows",
"125", "x86.NTWin32s",     "NTWin32s",      "WIN32_NT",  "Win32s and Windows NT",
"126", "x86.NTWindows_95", "NTWin95",       "WIN95_NT",  "Windows 95 and Windows NT",
"130", "all.pc",           "pc",            "ALL_PC",    "All PC Platforms",
"140", "all.windows",      "windows",       "ALL_WIN",   "All Windows Platforms",
);


# Map the 4th field in a partnumber to a vendor name and version.
# This array is used to get directory names or parts of directory names
# for tar tapes, distribution via web, and distribution via CDRom.
# For CDRom, use only 8 chars or fewer, use only A-Z, 0-9, _ (underscore).
# If you add a product, put in a name for all three!

$vendorStrMapWidth = 5;   # five elements per row
@vendorStrMapping = (
# Number, Name for           Name for                Short Name   Name for Prodrev
#           tar                Web                   for CDRom    sign off sheets
  "0", "",                    "",                     "",         "",
  "1", "owst4.1",             "owst4.1",              "OWST41",   "ObjectWorks 4.1",
  "2", "vw2.0",               "vw2.0",                "VW20",     "VisualWorks 2.0",
  "3", "vw2.5",               "vw2.5",                "VW25",     "VisualWorks 2.5",
  "4", "vw2.5.1",             "vw2.5.1",              "VW251",    "VisualWorks 2.5.1",
  "5", "vw2.5.2",             "vw2.5.2",              "VW252",    "VisualWorks 2.5.2",
  "6", "vw2.5.x",             "vw2.5.x",              "VW25X",    "VisualWorks 2.5.x",
  "7", "vw3.0",               "vw3.0",                "VW30",     "VisualWorks 3.0",
 "10", "stv2.0",              "stv2.0",               "STV20",    "Smalltalk/V 2.0",
 "11", "vse3.0",              "vse3.0",               "VSE30",    "ParcPlace-Digitalk/VisualSmalltalk Enterprise 3.0",
 "12", "vse3.0.1",            "vse3.0.1",             "VSE301",   "ParcPlace-Digitalk/VisualSmalltalk Enterprise 3.0.1",
 "13", "vse3.1",              "vse3.1",               "VSE31",    "ParcPlace-Digitalk/VisualSmalltalk Enterprise 3.1",
 "14", "vse3.1.1",            "vse3.1.1",             "VSE311",   "ParcPlace-Digitalk/VisualSmalltalk Enterprise 3.1.1",
 "15", "vse3.1.2",            "vse3.1.2",             "VSE312",   "ParcPlace-Digitalk/VisualSmalltalk Enterprise 3.1.2",
 "16", "vse4.0",              "vse4.0",               "VSE40",    "ParcPlace-Digitalk/VisualSmalltalk Enterprise 4.0",
 "20", "va2.0",               "va2.0",                "VA20",     "IBM VisualAge v2.0",
 "21", "va3.0",               "va3.0",                "VA30",     "IBM VisualAge v3.0",
 "22", "va3.0a",              "va3.0a",               "VA30A",    "IBM VisualAge v3.0a",
 "24", "va4.0",               "va4.0",                "VA40",     "IBM VisualAge v4.0",
 "50", "vw2.5_vse3.1_va3.0",  "vw2.5_vse3.1_va3.0",   "VW_VS_VA", "VisualWorks 2.5 and VisualSmalltalk 3.1 and VisualAge 3.0",
 "51", "all_st",              "all_st",               "ALL_ST",   "All vendor Smalltalks",
 "60", "tcc4.1",              "tcc4.1",               "TCC41",    "TogetherSoft TCC 4.1",
 "61", "tcc4.2",              "tcc4.2",               "TCC42",    "TogetherSoft TCC 4.2",
 "70", "vwv1.0",              "vwv1.0",               "VWAVE10",  "ParcPlace-Digitalk VisualWave 1.0",
"100", "msc7.0",              "msc7.0",               "MSC70",    "Microsoft C 7.0",
"110", "visualc1.10",         "visualc1.10",          "VISC110",  "Microsoft Visual C 1.10",
"111", "visualc2.1",          "visualc2.1",           "VISC21",   "Microsoft Visual C 2.1",
"140", "cset2.1",             "cset2.1",              "CSET21",   "IBM OS/2 CSet/2 2.1",
"141", "vac3.0",              "vac3.0",               "VAC30",    "IBM OS/2 VisualAge C/C++ v3.0",
"170", "mpwc3.3",             "mpwc3.3",              "MPWC33",   "Apple Macintosh MPW C 3.3",
"171", "eto18",               "eto18",                "ETO18",    "Apple Essential Tools & Objects 18",
"172", "cw9.0",               "cw9.0",                "CW90",     "Apple Macintosh Code Warrior 9.0",
"300", "sybase10.0",          "sybase10.0",           "SYB100",   "Sybase 10.0.x",
"310", "oracle7.2.2",         "oracle7.2.2",          "ORA72",    "Oracle 7.2.2.x",
"311", "oracle8i",            "oracle8i",             "ORA8i",    "Oracle 8i",
);

# Map the 6th field in a partnumber to a License type

$LicStrMapWidth = 2;   # two elements per row
@LicStrMapping = (
# Number, Name for           
# 
  "0", "",
  "1", "Nodelock",
  "2", "Floating",
);

sub parse_part_num {
  local($prodNum,*prodLine,*targArch,*verStr,
                   *vendCompat,*servCompat,*LicType) = @_;

  #=========================================================================
  # Parse the part number
  #=========================================================================

  $prodLine = $prodNum;
  $targArch = $prodNum;
  $verStr = $prodNum;
  $vendCompat = $prodNum;
  $servCompat = $prodNum;
  $LicType = $prodNum;

  $prodLine   =~ s/([^-]+)-[^-]+-[^-]+-[^-]+-[^-]+-.*/$1/;
  $targArch   =~ s/[^-]+-([^-]+)-[^-]+-[^-]+-[^-]+-.*/$1/;
  $verStr     =~ s/[^-]+-[^-]+-([^-]+)-[^-]+-[^-]+-.*/$1/;
  $vendCompat =~ s/[^-]+-[^-]+-[^-]+-([^-]+)-[^-]+-.*/$1/;
  $servCompat =~ s/[^-]+-[^-]+-[^-]+-[^-]+-([^-]+)-.*/$1/;
  $LicType      =~ s/[^-]+-[^-]+-[^-]+-[^-]+-[^-]+-(.*)/$1/;

  if ($prodLine eq $prodNum
      || $targArch eq $prodNum
      || $verStr eq $prodNum
      || $vendCompat eq $prodNum
      || $servCompat eq $prodNum
      || $LicType eq $prodNum) {
    print "Error parsing product number $prodNum:\n";
    print "prodLine is $prodLine\n";
    print "targArch is $targArch\n";
    print "verStr is $verStr\n";
    print "vendCompat is $vendCompat\n";
    print "servCompat is $servCompat\n";
    print "LicType is $LicType\n";
    return(1);
    }

  if ($LicType =~ /-/) {
    print "Error: too many '-' characters in part number $prodNum\n";
    return(1);
    }
    else {
      if ($LicType ne 0) {
        $LicPartNum = "1"; 
      }
    }

  # everything is cool, return success
  return(0);
  }


# Look through @table for $num in the first "column"
# and, if found, fill in *dirStr for the requested $mediaType (tar, web,
# or CDRom) and return 0 (sucess).
# If not found, fill in *dirStr with "" and return 1 (failure).

$tarMedia = 1;
$webMedia = 2;
$cdromMedia = 3;
$signoffMedia = 4;
$isExportable = 5;

sub isProductExportable {
  local($num) = @_;
  local($tableRows, $row, $retval);

  $tableRows = @prodStrMapping / $prodStrMapWidth;
  $row = 0;
  while ($row < $tableRows) {
    if (@prodStrMapping[($row * $prodStrMapWidth)] == $num) {
      # found the number in row $row
      $retval = @prodStrMapping[($row * $prodStrMapWidth) + $isExportable];
      return($retval);
      }
    $row += 1;
    }

  print "Error: could not find num $num in table\n";
  return(-1);
  }


sub translateNumToDirStr {
  local($num, *table, $tableWidth, $mediaType, *dirStr) = @_;
  local($tableRows, $row);

  # check for mediaType in range
  if (($mediaType != $tarMedia) &&
      ($mediaType != $webMedia) &&
      ($mediaType != $cdromMedia) &&
      ($mediaType != $signoffMedia)) {
    $dirStr = "";
    print "Error: mediaType of $mediaType out of range.\n";
    print "    must be $tarMedia, $webMedia, $cdromMedia, or $signoffMedia\n";
    return(1);
    }

  $tableRows = @table / $tableWidth;
  $row = 0;
  while ($row < $tableRows) {
    if (@table[($row * $tableWidth)] == $num) {
      # found the number in row $row
      $dirStr = @table[($row * $tableWidth) + $mediaType];
      return(0);
      }
    $row += 1;
    }

  print "Error: could not find num $num in table\n";
  return(1);
  }

sub partnum_to_dirname {
  local ($productNumber) = @_;
  local ($productLine, $targetArch, $verString);
  local ($vendorCompat, $beCompat, $patchNum);
  local ($prodStr, $archStr, $vendorStr, $patchStr);
  local ($rootName);

  #=========================================================================
  # Parse the part number
  #=========================================================================
  if (&parse_part_num($productNumber,*productLine,*targetArch,*verString,
                                     *vendorCompat,*beCompat,*patchNum)) {
    # partnumber is badly formed, error string already printed
    exit(1);
    }
  #=========================================================================
  # Perform the conversion
  #=========================================================================

  if (&translateNumToDirStr($productLine,*prodStrMapping,$prodStrMapWidth,
                                                          $tarMedia,*prodStr)) {
    print "$0 error: don't know how to pick prodStr for\n";
    print "    product line: \"$productLine\"\n";
    print "    product number: \"$productNumber\"\n";
    exit 1
    }

  if (&translateNumToDirStr($targetArch,*archStrMapping,$archStrMapWidth,
                                                          $tarMedia,*archStr)) {
    print "$0 error: don't know how to pick archStr for\n";
    print "    target arch: \"$targetArch\"\n";
    print "    product number: \"$productNumber\"\n";
    exit 1
    }
  $TARGETARCH = $archStr;  # hack


  if ( "$vendorCompat" eq "" ) {
    $vendorCompat = "0";
    }

  if (&translateNumToDirStr($vendorCompat,*vendorStrMapping,$vendorStrMapWidth,
                                                       $tarMedia, *vendorStr)) {
    print "$0 error: don't know how to pick vendorStr for\n";
    print "    vendorCompat: \"$vendorCompat\"\n";
    print "    product number: \"$productNumber\"\n";
    exit 1
    }

  # Nil out beCompat if it's noise.
  if ($beCompat eq "0" ) {
    $beCompat = "";
    }

  #=========================================================================
  # now build the resulting string
  #=========================================================================

  # Build basic three-part directory name
  $rootName=$prodStr . $verString;

  # add optional vendor
  if ($vendorStr ne "" ) {
    $rootName = $rootName . "+" . $vendorStr;
    }

  if (("$productLine" ne "12") && ("$productLine" ne "14")) {
    # add be compatibility string IFF this is NOT a GemStoneJ server product
    if ($beCompat ne "" ) {
      $rootName = $rootName . "-" . $beCompat;
      }
    }

  $rootName = $rootName . "-" . $archStr;

  if ($patchNum ne "0") {
    $patchStr = $patchNum;
    $patchStr =~ s/P([^-]*)/$1/;
    if ($productLine > 100) {
      $rootName = $rootName . "-PL" . $patchStr;
      }
    else {
      $rootName = $rootName . "-PatchLevel" . $patchStr;
      }
    }

  # print "partnum_to_dirname: Chosen directory name is $rootName\n";
  return $rootName;
  }

sub is_unix_product {
# The first and only arg is Field 2 of a part number (the architecture field).
# Returns 1 if the architecture value is for
#    1) a specific Unix platform, or
#    2) if it is for all Unix platforms, or
#    3) if it is for ALL platforms (unix, PC, Mac)
# Returns 0 otherwise.
  local ($arch) = @_;
  if (($arch < 11) || ($arch == 50) || ($arch == 100) || ($arch == 110)) {
    return(1);
    }
  else {
    return(0);
    }
  }

sub is_pc_product {
# The first and only arg is Field 2 of a part number (the architecture field).
# Returns 1 if the architecture value is for
#    1) a non-Unix platform, or
#    3) if it is for ALL platforms (unix, PC, Mac)
# Returns 0 otherwise.
  local ($arch) = @_;
  if (($arch != 11) && ($arch != 100)) {
    return(1);
    }
  else {
    return(0);
    }
  }

sub is_source_product {
# The first and only arg is Field 1 of a part number (the product name field).
# Returns 1 if the product is sources product.
# Returns 0 otherwise.
  local ($prodLine) = @_;
  if ((($prodLine > 100) && ($prodLine < 200)) ||
      (($prodLine >= 250) && ($prodLine < 400)) ||
      (($prodLine >= 450) && ($prodLine < 500)) ||
      (($prodLine >= 600) && ($prodLine < 700))) {
    return(1);
    }
  else {
    return(0);
    }
  }

1;
