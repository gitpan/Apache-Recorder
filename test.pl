BEGIN { $| = 1; print "1..4\n"; }

END {print "not ok 4\n" unless $cookie;}
END {print "not ok 3\n" unless $cgi;}
END {print "not ok 2\n" unless $storable;}
END {print "not ok 1\n" unless $loaded;}

use strict;
use vars qw( $loaded $storable $cgi $cookie );

use Apache::Recorder;
$loaded = 1;
print "ok 1\n";

use Storable;
$storable = 1;
print "ok 2\n";

use CGI;
$cgi = 1;
print "ok 3\n";

use CGI::Cookie;
$cookie = 1;
print "ok 4\n";
