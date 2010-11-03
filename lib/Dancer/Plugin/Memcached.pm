package Dancer::Plugin::Memcached;

use strict;
use warnings;

use 5.008;

use Dancer ':syntax';
use Dancer::Plugin;

use Cache::Memcached;
my $cache = Cache::Memcached->new;

=head1 NAME

Dancer::Plugin::Memcached - Cache response content to memcached

=head1 SYNOPSIS

This plugin gives Dancer the ability to get and store page content in a memcached server, 
which in specific configurations could give a performance boost - particulary on GET requests 
that incur significant database calls.

In your configuration, a list of servers with port numbers needs to be defined.

    plugins:
        Memcached:
	    servers: 
	        - "10.0.0.15:11211"
		- "10.0.0.17:11211"
            default_timeout: 86400

The C<default_timeout> specifies an fallback time for keys to expire from the
cache. If this value is less than 60*60*24*30 (30 days), time is assumed to be
seconds after the key was stored. If larger, it's considered an absolute Unix time.

In your package:

    package MyWebService;
    use Dancer;
    use Dancer::Plugin::Memcached;

    get '/' sub => {
        # Do your logic here
	...
        memcached_set template($foo);
    };

This plugin will use the PATH_INFO environment variable to store as the key so
routes that make use of parameters in the form of "/foo/:bar" will be cached, 
but GET/POST variables will not.

=head1 KEYWORDS

=head2 memcached_check

Will check for any route and return the page stored in memcached where available.

=cut

register memcached_check => sub
{
        before sub
        {
		my $set = plugin_setting;	
		$cache->set_servers($set->{servers});

                my $hit = $cache->get(request->{path_info});
                return $hit if($hit);
        };  
};

=head2 memcached_set($content, [$expiration])

For any given content, set and return the content. Expiration time for the set 
can optionally be set.

=cut

register memcached_set => sub
{
	my($content, $expiration) = @_;
	my $set = plugin_setting;	
	$cache->set_servers($set->{servers});

	my $hit = $cache->set(
		request->{path_info}, 
		$content, 
		$expiration || $set->{default_timeout}
	);

	return $content if $hit;
};

=head2 memcached_get($key)

Grab a specified key. Returns false if the key is not found.

=cut

register memcached_get => sub
{
	my $key = shift;

	my $set = plugin_setting;
	$cache->set_servers($set->{servers});
	
	return $cache->get($key);
};

=head2 memcached_store($key, $content, [$expiration])

This keyword is identical to memcached_set with the exception that you can set
any key name.

=cut

register memcached_store => sub
{
	my($key, $content, $expiration) = @_;
	my $set = plugin_setting;	
	$cache->set_servers($set->{servers});

	my $hit = $cache->set(
		$key, 
		$content, 
		$expiration || $set->{default_timeout}
	);

	return $content if $hit;
};


register_plugin;

=head1 AUTHOR

Squeeks, C<< <squeek at cpan.org> >>

=head1 SEE ALSO

Dancer Web Framework - L<Dancer>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Squeeks.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; 
