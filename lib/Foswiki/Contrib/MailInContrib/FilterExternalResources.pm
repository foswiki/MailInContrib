#
# Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2010 Foswiki Contributors. All Rights Reserved.
# Foswiki Contributors are listed in the AUTHORS file in the root
# of this distribution. NOTE: Please extend that file, not this notice.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# As per the GPL, removal of this notice is prohibited.
package Foswiki::Contrib::MailInContrib::FilterExternalResources;
use Foswiki::Contrib::MailInContrib::Filter;
our @ISA = qw( Foswiki::Contrib::MailInContrib::Filter );

use strict;
use Foswiki;
use Assert;

sub process {
    my $this = shift;

    # my ($content) = @_;

    return unless $this->contentType =~ m{text/html};

    if ( $this->options->{safeurlpattern} ) {
        $this->{safeUrlPattern} = qr/$this->options->{safeurlpattern}/;
    }
    elsif ( $this->options->{safedomains} ) {
        my @domains = split /[, ]+/, $this->options->{safedomains};

        for my $domain (@domains) {
            my $wildcardPrefix = $domain =~ s/^\*\.//;

            # Prevent example.com from matching example.com.evil.net
            $domain .= '/' unless $domain =~ m{/};

            # Convert to a regex and escape characters like .
            $domain = qr/\Q$domain/;

            if ($wildcardPrefix) {
                $domain = qr/[\w.]*\.$domain/;
            }
        }

        my $domainsPattern = join( '|', @domains );

        # Also allow urls on the same server (i.e. no http)
        $this->{safeUrlPattern} = qr{(?!http)|https?://(?:$domainsPattern)};
    }
    else {
        my $pubUrl = Foswiki::Func::expandCommonVariables('%PUBURL%');

        $this->{safeUrlPattern} = qr/(?!http)|\Q$pubUrl/;
    }

    $this->processTag( $_[0], { tag => [qw/script style img iframe/] },
        \&_processOneTag );
    $this->processAttribute( $_[0], { attr => ['style'] },
        \&_processOneAttribute );
}

sub _processOneTag {
    my ( $this, $html, $tagName ) = @_;

    if ( $html =~ /^[^>]*\bsrc\s*=\s*["'](?!$this->{safeUrlPattern})/i ) {

        # Remove the whole tag
        return '';
    }

    return $html;
}

sub _processOneAttribute {
    my ( $this, $html, $tagName, $attrName, $attrValue, $quote ) = @_;

    if ( $attrValue =~ /url.*(http.*)/i ) {
        my $url = $1;
        if ( $url !~ /^$this->{safeUrlPattern}/ ) {

            # remove the whole attribute
            return '';
        }
    }

    return $html;
}

1;

