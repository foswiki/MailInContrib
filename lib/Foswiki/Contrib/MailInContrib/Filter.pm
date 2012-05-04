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
package Foswiki::Contrib::MailInContrib::Filter;

# Base class for mail filters

use strict;
use Foswiki;
use Assert;

sub new {
    my $class    = shift;
    my $box      = shift;
    my $topMime  = shift;
    my $thisMime = shift;
    my $options  = shift;

    my $this = bless {}, $class;

    $this->{box}      = $box;
    $this->{topMime}  = $topMime;
    $this->{thisMime} = $thisMime;
    $this->{options}  = $options;

    return $this;
}

sub box {
    my $this = shift;
    return $this->{box};
}

sub contentType {
    my $this = shift;
    return $this->{thisMime}->content_type || 'text/plain';
}

sub mime {
    my $this = shift;
    return $this->{thisMime};
}

sub topLevelMime {
    my $this = shift;
    return $this->{topMime};
}

sub options {
    my $this = shift;
    return $this->{options};
}

sub processTag {
    my $this = shift;

    # my ($html, $filter, $handler) = @_;
    my ( $filter, $handler ) = ( $_[1], $_[2] );

    my $tagPattern = '\w+';
    my @uglyTags;
    if ( $filter->{tag} ) {

        @uglyTags = grep { $_ =~ /^img$/i } @{ $filter->{tag} };

        $tagPattern = join '|', @{ $filter->{tag} };
    }

    pos( $_[0] ) = 0;
    $_[0] =~ s{\G(.*?)                      # HTML before the tag
                (                           # Start of the html to process
                 <\s*($tagPattern)          #   opening tag
                 \b                         #   end of tagname
                 [^>]*                      #   whitespace or attributes
                 (?:
                   >.*?</\3>                #   End of tag, content, and closing tag
                 |                          #     or
                   />                       #   End of tag, and tag does not have content
                 )
               )                            # End of html to process
              }{pos($_[0]) = $-[2] + 3; $1.$this->$handler($2, $3)}isxge;

    if (@uglyTags) {
        $tagPattern = join '|', @uglyTags;
        pos( $_[0] ) = 0;
        $_[0] =~ s{\G(.*?)                      # HTML before the tag
                   (                            # Start of the html to process
                     <\s*($tagPattern)          #   opening tag
                     \b                         #   end of tagname
                     [^>]*                      #   whitespace or attributes
                     >                          #   End of tag, and tag does not have content
                   )                            # End of html to process
                  }{pos($_[0]) = $-[2] + 3; $1.$this->$handler($2, $3)}isxe;
    }
}

sub processAttribute {
    my $this = shift;

    # my ($html, $filter, $handler) = @_;
    my ( $filter, $handler ) = ( $_[1], $_[2] );

    my $tagPattern = '\w+';
    if ( $filter->{tag} ) {
        $tagPattern = join '|', @{ $filter->{tag} };
    }

    my $attrPattern = '\w+';
    if ( $filter->{attr} ) {
        $attrPattern = join '|', @{ $filter->{attr} };
    }

    $_[0] =~ s{<\s*($tagPattern)          # opening tag
               \b                         # end of tagname
               (                          # Start of attributes to process
                 [^>]*                    #   whitespace or attributes
                 \b                       #   start of attribute name
                 (?:$attrPattern)         #   name(s) of relevant attributes
                 \b=["']                  #   end of attribute name
                 [^>]*                    #   whitespace or attributes
               )                          # End of attributes to process
               (/?                        # Possible / before >
               >)                         # end of tag
              }{$this->__micf_processAllAttributes($1, $2, $3, $attrPattern, $handler)}isgxe;
}

sub __micf_processAllAttributes {
    my ( $this, $tagName, $attributes, $close, $attrPattern, $handler ) = @_;

    my $result = "<$tagName";

    my $lastPos = 0;
    while ( $attributes =~ /(\s+(\w+)\s*=\s*(['"])(.*?)\3)/g ) {
        my $wholeAttribute = $1;
        my $attrName       = $2;
        my $quote          = $3;
        my $attrValue      = $4;

        $lastPos = pos($attributes); # Save the position of the end of the match

        if ( $attrPattern and $attrName =~ /$attrPattern/ ) {
            $result .=
              $this->$handler( $wholeAttribute, $tagName, $attrName, $attrValue,
                $quote );
        }
        else {
            $result .= $wholeAttribute;
        }
    }

    # tolerate malformed attributes, and transfer any trailing whitespace
    $result .= substr( $attributes, $lastPos );

    # close the tag
    $result .= $close;

    return $result;
}

sub process {
    my $this = shift;

    # my ($content) = @_;
    #
    # You can work on $content in place by using the special perl
    # variable $_[0]. These allow you to operate on $content
    # as if it was passed by reference; for example:
    # $_[0] =~ s/SpecialString/my alternative/ge;

    ASSERT(0);    # Derived classes must override this function
}

1;

