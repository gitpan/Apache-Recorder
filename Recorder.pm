package Apache::Recorder;

use strict;
use vars qw( $VERSION );
$VERSION = '0.03';


use Apache::Constants qw(:common);
use Apache::File;
use CGI::Cookie;
use Apache::URI;
use Apache::Log;

sub handler {
    my ( $r ) = shift;
    my ( $id ) = &get_state( $r );
    return DECLINED unless $id;

    my ($log) = $r->server->log();
    $log->error( "Apache::Recorder is running." );


    my ( $parsed_uri ) = $r->parsed_uri;
    my ( $host ) = $parsed_uri->hostname() || $r->subprocess_env( "SERVER_NAME" ) || 'localhost';
    my ( $uri ) = "http://" . $host . $parsed_uri->path();
    my ( $file_name ) = $r->filename;
    $log->error( "Apache::Recorder: ", $file_name );

    #Process CGI GET / POST Parameters
    my ( %params ) = $r->method eq 'POST' ? $r->content : $r->args; 
    
    my ( $request_type ) = $r->method;
    use constant WORLD_WRITEABLE_DIR => "/usr/tmp/";
    #die "Cannot write to WORLD_WRITEABLE_DIR: $!" unless ( -w WORLD_WRITEABLE_DIR );
    
    my ( $config_file ) = WORLD_WRITEABLE_DIR . "recorder_conf"."_".$id;
    my ( $success ) = &write_config_file( $config_file, $uri, $request_type, \%params, $log );
    return DECLINED;
}

sub get_state {
    my ( $r ) = shift;

    my ( %cookies ) = CGI::Cookie->parse( $r->header_in( 'Cookie' ) );
    if (exists( $cookies{ 'HTTPRecorderID' } ) ) {
	return $cookies{ 'HTTPRecorderID' }->value;
    }
}

sub write_config_file {
    my ( $config_file ) = shift;
    my ( $uri) = shift;
    my ( $request_type ) = shift;
    my ( $params ) = shift;
    my ( $log ) = shift;
    use Storable qw( lock_store lock_retrieve );
    #maintain insert order in hash
    $Storable::canonical = 1;
    my ( $history );
    my ( $click ) = {
	url => $uri, 
	method => $request_type,
	params => $params, 
        acceptcookie => '1',
        sendcookie => '1',
        print_results => '1',
    };
    if ( -e $config_file ) { 
        $history = lock_retrieve( $config_file ) || undef;
        my ( $count ) = 0;
        foreach my $key ( keys %$history ) {
            $count = $key;
        }
	$log->error( "TESTENGINE: \$count is $count");
        $count++;
	$history->{ $count } = $click;
	$log->error( "TESTENGINE: \$count is $count, \$uri is $uri, \$request_type is $request_type");
    }
    else { 
        $history->{ '1' } = $click;
    }

    lock_store $history, $config_file; 
    1;
}

1;
__END__

=head1 NAME

Apache::Recorder - mod_perl handler to record HTTP sessions

=head1 SYNOPSIS

To activate the Apache::Recorder handler in webroot (where webroot is /www/perl/htdocs/) add the following lines to your httpd.conf:

    <Directory /www/perl/htdocs>

	SetHandler perl-script

	PerlHandler Apache::Recorder

    </Directory>

=head1 DESCRIPTION


=head1 AUTHOR

Chris Brooks <cbrooks@organiccodefarm.com>

=head1 SEE ALSO

perl(1).

=head1 FUTURE IMPROVEMENTS

One problem is how to handle cached pages.  One benefit of running the recorder on the client side is that it knows every page that the user requests.  On the server side, it only knows the pages that are actually served by the server.

=cut
