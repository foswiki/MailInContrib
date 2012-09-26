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
package Foswiki::Contrib::MailInContrib::NoScript;
use Foswiki::Contrib::MailInContrib::Filter;
our @ISA = qw( Foswiki::Contrib::MailInContrib::Filter );

use strict;
use Foswiki;
use Assert;

sub process {
    my $this = shift;

    # my ($content) = @_;
    #
    # You can work on $content in place by using the special perl
    # variable $_[0]. These allow you to operate on $content
    # as if it was passed by reference; for example:
    # $_[0] =~ s/SpecialString/my alternative/ge;
    return unless $this->contentType =~ m{text/html};

    $this->processTag( $_[0], { tag => [qw/script/] }, \&_processOneTag );
    $this->processAttribute( $_[0], {}, \&_processOneAttribute );
}

sub _processOneTag {

    # my ($this, $html, $tagName) = @_;

    return '';
}

sub _processOneAttribute {
    my ( $this, $html, $tagName, $attrName, $attrValue, $quote ) = @_;

    if ( $attrName =~ /^on/i ) {

        # remove the whole attribute
        return '';
    }

    return $html;
}

1;

