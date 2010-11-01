#!perl

use strict;
use warnings;

use Test::More import => ['!pass'];

unless ( $ENV{D_P_M_SERVER} )
{
    plan( skip_all => "Environment variable D_P_M_SERVER not set" );
}

use lib './t';
use_ok 'TestApp';

use Dancer::Test appdir => '..';
use Dancer;

setting plugins => { Memcached => { servers => [ $ENV{D_P_M_SERVER} ] } };

my $time = time;

route_exists        [GET => '/'], "GET / is handled";
response_status_is  [GET => '/'], 200, 'response status is 200 for /';
response_content_is [GET => '/'], "Test Module Loaded", 
	"got expected response content for GET /";

response_status_is  [GET => '/set_test/'.$time], 200, 'response status is 200 for /get_test';
response_content_is [GET => '/set_test/'.$time], $time, 
	"got expected response content for GET /set_test";

response_status_is  [POST => '/get_test'], 200, 'response status is 200 for /get_test';
response_content_is [POST => '/get_test', { data => '/set_test/'.$time }], $time, 
	"got expected response content for POST /get_test";

response_status_is  [POST => '/store_test'], 200, 'response status is 200 for /get_test';
response_content_is [POST => '/store_test', { key => 'test', data => $time }], $time, 
	"got expected response content for POST /store_test";

response_status_is  [GET => '/fetch_stored', { key => 'test' }], 200, 'response status is 200 for /';
response_content_is [GET => '/fetch_stored', { key => 'test' }], $time, 
	"got expected response content for GET /";


done_testing;
