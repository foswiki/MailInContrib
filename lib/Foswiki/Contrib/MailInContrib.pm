#
# Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2009 Foswiki Contributors. All Rights Reserved.
# Foswiki Contributors are listed in the AUTHORS file in the root
# of this distribution. NOTE: Please extend that file, not this notice.
#
# Additional copyrights apply to some or all of the code in this module
# as follows:
# Copyright (C) 2005 TWiki Contributors. All Rights Reserved.
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
package Foswiki::Contrib::MailInContrib;

use strict;
use Foswiki;
use Assert;

use Email::Folder;
use Email::FolderType::Net;
use Email::MIME;
use Email::Delete;
use Time::ParseDate;
use Error qw( :try );
use Carp;

our $VERSION = '$Rev: 10183$';
our $RELEASE = '18 Jan 2010';
our $SHORTDESCRIPTION = 'Supports submissions to Foswiki via e-mail';

BEGIN {
    $SIG{__DIE__} = sub { Carp::confess $_[0] };
}

{

    package MIMEFolder;

    use base qw/Email::Folder/;

    sub bless_message {
        my $self = shift;
        my $message = shift || die "You must pass a message\n";

        return Email::MIME->new($message);
    }
}

=pod

---++ ClassMethod new( $session )
   * =$session= - ref to a Foswiki object
Construct a new inbox processor.

=cut

sub new {
    my ( $class, $session, $debug ) = @_;
    my $this = bless( {}, $class );
    $this->{session} = $session;
    $this->{debug}   = $debug;

    # Find out when we last processed mail
    my $workdir = Foswiki::Func::getWorkArea('MailInContrib');
    if ( -e "$workdir/timestamp" ) {
        open( F, "<$workdir/timestamp" ) || die $!;
        $this->{lastMailIn} = <F>;
        chomp( $this->{lastMailIn} );
        close(F);
    }
    else {
        $this->{lastMailIn} = 0;
    }

    return $this;
}

=pod

---++ ObjectMethod wrapUp( $box )
Clean up after processing inboxes, setting the time-stamp
indicating when the processor was last run.

=cut

#SMELL: could this be done in a DESTROY?
sub wrapUp {
    my $this = shift;

    # re-stamp
    my $workdir = Foswiki::Func::getWorkArea('MailInContrib');
    open( F, ">$workdir/timestamp" ) || die $!;
    print F time(), "\n";
    close(F);
}

sub _getUser {
    my $u = shift;

    if ( $Foswiki::Plugins::SESSION->{users}->can('getCanonicalUserID') ) {
        return $Foswiki::Plugins::SESSION->{users}->getCanonicalUserID($u);
    }
    else {
        return $Foswiki::Plugins::SESSION->{users}->findUser($u);
    }
}

=pod

---++ ObjectMethod processInbox( $box )
   * =$box= - hash describing the box
Scan messages in the box that have been received since the last run,
and process them for inclusion in Foswiki topics.

=cut

sub processInbox {
    my ( $this, $box ) = @_;

    $Foswiki::Plugins::SESSION = $this->{session};

    die "No folder specification" unless $box->{folder};

    my $ftype = Email::FolderType::folder_type( $box->{folder} );
    print STDERR "Process $ftype folder $box->{folder}\n" if $this->{debug};

    my $folder = new MIMEFolder( $box->{folder} );

    my $user;
    my %kill;

    # Set defaults if necessary
    $box->{topicPath}  ||= 'subject';
    $box->{defaultWeb} ||= '';
    $box->{onNoTopic}  ||= 'error';
    $box->{onError}    ||= 'log';
    $box->{onSuccess}  ||= 'log';
    $box->{content}->{type} ||= 'text';
    $box->{content}->{processors} ||= [
        { pkg => 'Foswiki::Contrib::MailInContrib::NoScript' },
        { pkg => 'Foswiki::Contrib::MailInContrib::FilterExternalResources' },
    ];

    # Load the mail templates
    Foswiki::Func::loadTemplate('MailInContrib');
    # Load second so that user templates override
    Foswiki::Func::loadTemplate('MailInContribUser');

    print STDERR "Scanning $box->{folder}\n" if $this->{debug};
    my $mail;    # an Email::Simple object
    my $num = -1;    # message number
    while ( ( $mail = $folder->next_message() ) ) {
        $num++;

        my $received = 0;
        foreach my $receipt ( $mail->header('Received') ) {
            if ( $receipt =~ /; (.*?)$/ ) {
                $receipt = Time::ParseDate::parsedate($1);
                $received = $receipt if $receipt > $received;
            }
        }
        if ( !$received && $mail->header('Date') ) {

            # Use the send date
            $received = Time::ParseDate::parsedate( $mail->header('Date') );
        }
        $received ||= time();

     # Try to get the target topic by
     #    1. examining the "To" and "cc" addresses to see if either has
     #       a valid web.wikiname (if enabled in config)
     #    2. if the subject line starts with a valid Foswiki Web.WikiName
     #       (if optionally followed by a colon, the rest of the subject
     #       line will be ignored)
     #    3. Routing the comment to the spambox if it is enabled
     #    4. Otherwise replying to the user to say "no thanks" if replyonnotopic
        my ( $web, $topic, $user );

        my $subject = $mail->header('Subject');
        my $originalSubject = $subject;

        my $from = $mail->header('From');

        print STDERR "Message from $from: ", $mail->header('Subject'), "\n"
          if $this->{debug};

        $from =~ s/^.*<(.*)>.*$/$1/;
        my $targets = $this->{session}->{users}->findUserByEmail($from);
        if ( $targets && scalar(@$targets) ) {
            $user = $targets->[0];
        }

        my @to = split( /,\s*/, $mail->header('To') || '' );
        if ( defined $mail->header('CC') ) {
            push( @to, split( /,\s*/, $mail->header('CC') ) );
        }

        # Use the address in the <> if there is one
        @to = map { /^.*<(.*)>.*$/ ? $1 : $_; } @to;
        print STDERR "Targets: ", join( ' ', @to ), "\n" if $this->{debug};
        print STDERR "Subject: $subject\n" if $this->{debug};

        unless ($user) {
            unless ( $box->{user} && ( $user = _getUser( $box->{user} ) ) ) {
                $this->_onError(
                    $box,
                    $mail,
                    'Could not determine submitters WikiName from'
                      . "\nFrom: $from\nand there is no valid default username",
                    \%kill,
                    $num
                );
                next;
            }
        }

        print STDERR "User is '", ( $user || 'undefined' ), "'\n"
          if ( $this->{debug} );

        # See if we can get a valid web.topic out of to: or cc:
        if ( $box->{topicPath} =~ /\bto\b/ ) {
            foreach my $target (@to) {
                next
                  unless $target =~
/^(?:($Foswiki::regex{webNameRegex})\.)($Foswiki::regex{topicNameRegex})\@/i;
                my ( $guessweb, $guesstopic ) =
                  Foswiki::Func::normalizeWebTopicName(
                    ( $1 || $box->{defaultWeb} ), $2 );
                if ( Foswiki::Func::topicExists( $guessweb, $guesstopic ) ) {

                    # Found an existing topic
                    ( $web, $topic ) = ( $guessweb, $guesstopic );
                    last;
                }
            }
        }

        # If we didn't get the name of an existing topic from the
        # To: or CC:, use the Subject:
        if (  !$topic
            && $box->{topicPath} =~ /\bsubject\b/
            && $subject =~
s/^(\s*(?:($Foswiki::regex{webNameRegex})\.)?($Foswiki::regex{topicNameRegex})(:\s*|\s*$))/$box->{removeTopicFromSubject} ? '' : $1/e
          )
        {
            ( $web, $topic ) = Foswiki::Func::normalizeWebTopicName(
                ( $2 || $box->{defaultWeb} ), $3 );

            # This time the topic doesn't have to exist
        }

        $web ||= $box->{defaultWeb};

        print STDERR "Topic $web.", $topic || '', "\n" if $this->{debug};

        unless ( Foswiki::Func::webExists($web) ) {
            $topic = '';

            # restore original subject in case the subject line specified a web that does not exist
            $subject = $originalSubject; 
        }

        if ( !$topic ) {
            if ( $box->{onNoTopic} =~ /\berror\b/ ) {
                $this->_onError(
                    $box,
                    $mail,
                    'Could not add your submission; no valid web.topic found in'
                      . "\nTo: "
                      . $mail->header('To')
                      . "\nSubject: "
                      . $subject,
                    \%kill,
                    $num
                );
            }
            if ( $box->{onNoTopic} =~ /\bspam\b/ ) {
                if ( $box->{spambox} && $box->{spambox} =~ /^(.*)\.(.*)$/ ) {
                    ( $web, $topic ) = ( $1, $2 );
                }
            }
            print STDERR "Skipping; no topic\n" if ( $this->{debug} );
            next unless $topic;
        }

        if ( $box->{ignoreMessageTime} or $received > $this->{lastMailIn} ) {
            my $err = '';
            unless ( Foswiki::Func::webExists($web) ) {
                $err = "Web $web does not exist";
            }
            else {
                my $sender = $mail->header('From') || 'unknown';

                my @attachments = ();
                my $body        = '';

                $this->_extract( $mail, \$body, \@attachments, $box );

                print "Received mail from $sender for $web.$topic\n";

                $err .= $this->_saveTopic( $user, $web, $topic, $body, $subject,
                    \@attachments );
            }
            if ($err) {
                $this->_onError(
                    $box,
                    $mail,
"Foswiki encountered an error while adding your mail to $web.$topic: $err",
                    \%kill,
                    $num
                );
            }
            else {
                if ( $box->{onSuccess} =~ /\breply\b/ ) {
                    $this->_reply( $box, $mail,
"Thank you for your successful submission to $web.$topic"
                    );
                }
                if ( $box->{onSuccess} =~ /\bdelete\b/ ) {
                    $kill{ $mail->header('Message-ID') } = $num;
                }
            }
        }
        elsif ( $this->{debug} ) {
            print STDERR "Skipping; late: $received <= $this->{lastMailIn}\n";
        }
    }

    eval 'use Email::Delete';
    if ($@) {
        Foswiki::writeWarning("Cannot delete from inbox: $@\n");
    }
    else {
        Email::Delete::delete_message(
            from     => $box->{folder},
            matching => sub {
                my $test = shift;
                my $message_id = $test->header('Message-ID');
                if ( defined $message_id and defined $kill{ $message_id } ) {
                    print STDERR "Delete $message_id\n"
                      if $this->{debug};
                    return 1;
                }
                return 0;
            }
        );
    }
}

sub _onError {
    my ( $this, $box, $mail, $mess, $kill, $num ) = @_;

    $this->{error} = $mess;    # used by the tests

    print STDERR "ERROR: $mess\n" if ( $this->{debug} );

    if ( $box->{onError} =~ /\blog\b/ ) {
        Foswiki::Func::writeWarning($mess);
    }
    if ( $box->{onError} =~ /\breply\b/ ) {
        $this->_reply( $box, $mail,
            "Foswiki found an error in your e-mail submission\n\n$mess\n\n"
              . $mail->as_string() );
    }
    if ( $box->{onError} =~ /\bdelete\b/ ) {
        $kill->{ $mail->header('Message-ID') } = $num;
    }
}

sub _extract {
    my ( $this, $mime, $text, $attach, $box ) = @_;

	$this->{currentBox} = $box;
	$this->{currentMime} = $mime;

    if ($box->{content}->{type} =~ /debug/i) {
        $$text .= "<verbatim>" . $mime->as_string . "</verbatim>";
    }
    elsif ($box->{content}->{type} =~ /html/i) {
        $this->_extractHtmlAndAttachments($mime, $text, $attach);
    }
    else {
        $this->_extractPlainTextAndAttachments($mime, $text, $attach);
    }
}

sub _currentBox {
	my $this = shift;
	return $this->{currentBox};
}

sub _currentMime {
	my $this = shift;
	return $this->{currentMime};
}

sub _extractHtmlAndAttachments {
    my ( $this, $mime, $text, $attach ) = @_;
    my $ct = $mime->content_type || 'text/plain';
    my $dp = $mime->header('Content-Disposition') || 'inline';
    print STDERR "\nContent-type: $ct\n" if $this->{debug};
    if ($ct =~ m[multipart/mixed]) {
        $this->_extractMultipartMixed($mime, $text, $attach);
    }
    elsif ($ct =~ m[multipart/alternative]) {
        $this->_extractMultipartAlternative($mime, $text, $attach);
    }
    elsif ( $ct =~ m[multipart/related] ) {
        my $found;
        $found = _extractMultipartHtml($mime, $text, $attach);
        print STDERR "Found multipart/related HTML\n" if $found and $this->{debug};
        if (not $found)
        {
            print STDERR "Cannot find HTML. Extracting plain text\n" if $this->{debug};
            $this->_extractPlainTextAndAttachments($mime, $text, $attach);
        }
    }
    elsif ( $ct =~ m[text/html] and $dp =~ /inline/ ) {
        print STDERR "Extracting text/html\n" if $this->{debug};
        $this->_extractPlainHtml($mime, $text);
    }
    else {
        print STDERR "Extracting plain text and attachments\n" if $this->{debug};
        $this->_extractPlainTextAndAttachments($mime, $text, $attach);
    }
}

sub _extractMultipartMixed {
    my ( $this, $mime, $text, $attach ) = @_;
    foreach my $part ( grep { $_ != $mime } $mime->parts() ) {
        print STDERR "Multipart/mixed: Recursing\n" if $this->{debug};
        $this->_extractHtmlAndAttachments($part, $text, $attach);
    }
}

sub _extractMultipartAlternative {
    my ( $this, $mime, $text, $attach ) = @_;

    print STDERR "Multipart/alternative\n" if $this->{debug};
    # See what alternatives are available
    my @alternates = map +{ 
        mime => $_, 
        ct => $_->content_type || 'text/plain', 
      }, grep { $_ != $mime } $mime->parts();

    my ($multipartRelatedAlternate) = grep { $_->{ct} =~ m[multipart/related] } @alternates;
    my ($htmlAlternate) = grep { $_->{ct} =~ m[text/html] } @alternates;

    # Pick one
    my $found;
    if ($multipartRelatedAlternate) {
        $found = $this->_extractMultipartHtml($multipartRelatedAlternate->{mime}, $text, $attach);
        print STDERR "Found multipart/related HTML\n" if $found and $this->{debug};
    }
    if ($htmlAlternate and not $found) {
        $found = $this->_extractPlainHtml($htmlAlternate->{mime}, $text);
        print STDERR "Found text/html\n" if $found and $this->{debug};
    }
    if (not $found)
    {
        print STDERR "Cannot find HTML - Extracting plain text\n" if $this->{debug};
        $this->_extractPlainTextAndAttachments($mime, $text, $attach);
    }
}

sub _extractMultipartHtml {
    my ( $this, $mime, $text, $attach ) = @_;
    my @bits = map +{ 
        mime => $_, 
        ct => $_->content_type || 'text/plain', 
        dp => $_->header('Content-Disposition') || 'inline'
      }, grep { $_ != $mime } $mime->parts();
    my ($htmlBit) = grep { $_->{ct} =~ m[text/html] and $_->{dp} =~ /inline/ } @bits;
    return unless $htmlBit; # Not found

    my $html = $this->_extractAndTrimHtml($htmlBit->{mime});
    return unless $html;
    for my $bit (grep { $_ != $htmlBit } @bits)
    {
        my $filename = $bit->{mime}->filename();
        ($filename) = Foswiki::Sandbox::sanitizeAttachmentName( $bit->{mime}->filename() ) if defined $filename;
        my $cid = $bit->{mime}->header('Content-ID') || '';
        my $cid_used = '';
        print STDERR "cid:[$cid]\n" if $cid and $this->{debug};
        if ($cid =~ /^\s*<?((.*?)\@.*?)>?\s*$/) {
            $cid = $1;
            ($filename) = Foswiki::Sandbox::sanitizeAttachmentName($2);
            $cid_used = ($html =~ s{"cid:\Q$cid\E"}{"%ATTACHURLPATH%/$filename"});
        }
        if ( $filename and ($bit->{dp} !~ /inline/ or ($cid and $cid_used) ) ) {
            push(
                @$attach,
                {
                    payload  => $bit->{mime}->body(),
                    filename => $filename
                }
            );
        }
    }
    $$text .= "<literal><div class=\"foswikiMailInContribHtml\">$html</div></literal>\n";
    return 1;
}

sub _extractPlainHtml {
    my ( $this, $mime, $text, $box, $topMime ) = @_;
    my $html = $this->_extractAndTrimHtml($mime);
    return unless $html;
    $$text .= "<literal><div class=\"foswikiMailInContribHtml\">$html</div></literal>\n";
    return 1;
}

sub _extractAndTrimHtml {
    my ($this, $mime, $box, $topMime) = @_;
    return unless $mime;
    my $html = $mime->body();
    return unless $html;

    # Remove anything outside the body tag, and change the body tag into a div tag
    # It is better to keep the body tag as a tag (and not just discard it altogether)
    # because that tag sometimes has attributes that should be retained.
    $html =~ s{.*<body([^>]*>.*)</body>.*}{<div$1</div>}is;

	$html = $this->_applyProcessors($mime, $html);

    return unless $html =~ /\S/;
    return $html;
}

sub _applyProcessors {
    my ($this, $mimeForContent, $content) = @_;
    return unless $mimeForContent;

	my $box = $this->_currentBox();
	return $content unless $box
	    and $box->{content}->{processors} 
		and ref($box->{content}->{processors}) eq 'ARRAY';

	my $topMime = $this->_currentMime();

    for my $processorCfg (@{ $box->{content}->{processors} }) {
        my $pkg = $processorCfg->{pkg};
        eval "use $pkg;";
        die $@ if $@;

        my $processor = $pkg->new($box, $topMime, $mimeForContent, $processorCfg);
        $processor->process($content);
    }

	return $content;
}


# Extract plain text and attachments from the MIME
sub _extractPlainTextAndAttachments {
    my ( $this, $mime, $text, $attach ) = @_;

    foreach my $part ( $mime->parts() ) {
        my $ct = $part->content_type || 'text/plain';
        my $dp = $part->header('Content-Disposition') || 'inline';
        if ( $ct =~ m[text/plain] && $dp =~ /inline/ ) {
            $$text .= $this->_applyProcessors($part, $part->body());
        }
        elsif ( $part->filename() ) {
            push(
                @$attach,
                {
                    payload  => $part->body(),
                    filename => $part->filename()
                }
            );
        }
        elsif ( $part != $mime ) {
            $this->_extractPlainTextAndAttachments( $part, $text, $attach );
        }
    }
}

sub _saveTopic {
    my ( $this, $user, $web, $topic, $body, $subject, $attachments ) = @_;
    my $err = '';

    my $curUser = $Foswiki::Plugins::SESSION->{user};
    $Foswiki::Plugins::SESSION->{user} = $user;

    try {
        my ( $meta, $text ) = Foswiki::Func::readTopic( $web, $topic );

        my $opts;
        if ( $text =~ /<!--MAIL(?:{(.*?)})?-->/ ) {
            $opts = new Foswiki::Attrs($1);
        }
        else {
            $opts = new Foswiki::Attrs('');
        }
        $opts->{template} ||= 'normal';
        $opts->{where}    ||= 'bottom';

        # the $insert variable is initialized from
        # %SYSTEMWEB%/MailInContribTemplate and the recommended way to change
        # the look and feel of the output pages is to copy
        # MailInContribTemplate as MailInContribUserTemplate and edit to
        # taste. - VickiBrown - 07 Sep 2007
        my $insert =
          Foswiki::Func::expandTemplate( 'MAILIN:' . $opts->{template} );
        $insert ||=
          "   * *%SUBJECT%*: %TEXT% _%WIKIUSERNAME% @ %SERVERTIME%_\n";
        $insert =~ s/%SUBJECT%/$subject/g;
        $body   =~ s/\r//g;

        my $attached = 0;
        my $atts     = '';
        foreach my $att (@$attachments) {
            $attached = 1;
            $err .= $this->_saveAttachment( $web, $topic, $att );
            my $tmpl = Foswiki::Func::expandTemplate(
                'MAILIN:' . $opts->{template} . ':ATTACHMENT' );
            if ($tmpl) {
                $tmpl =~ s/%A_FILE%/$att->{filename}/g;
                $atts .= $tmpl;
            }
            else {
                print 'No template for attachments' if $this->{debug};
            }
        }
        $insert =~ s/%ATTACHMENTS%/$atts/;

        $insert =~ s/%TEXT%/$body/g;
        $insert = Foswiki::Func::expandVariablesOnTopicCreation($insert);

        # Reload the topic if we added attachments.
        if ($attached) {
            ( $meta, $text ) = Foswiki::Func::readTopic( $web, $topic );
        }

        if ( $opts->{where} eq 'top' ) {
            $text = $insert . $text;
        }
        elsif ( $opts->{where} eq 'bottom' ) {
            $text .= $insert;
        }
        elsif ( $opts->{where} eq 'above' ) {
            $text =~ s/(<!--MAIL(?:{.*?})?-->)/$insert$1/;
        }
        elsif ( $opts->{where} eq 'below' ) {
            $text =~ s/(<!--MAIL(?:{.*?})?-->)/$1$insert/;
        }

        print STDERR "Save topic $web.$topic:\n$text\n" if ( $this->{debug} );

        ASSERT( !$meta || $meta->isa('Foswiki::Meta') ) if DEBUG;
        Foswiki::Func::saveTopic(
            $web, $topic, $meta, $text,
            {
                comment          => "Submitted by e-mail",
                forcenewrevision => 1
            }
        );

    }
    catch Foswiki::AccessControlException with {
        my $e = shift;
        $err .= $e->stringify();
    }
    catch Error::Simple with {
        my $e = shift;
        $err .= $e->stringify();
    }
    finally {
        $Foswiki::Plugins::SESSION->{user} = $curUser;
    };
    return $err;
}

sub _saveAttachment {
    my ( $this, $web, $topic, $attachment ) = @_;
    my $filename = $attachment->{filename};
    my $payload  = $attachment->{payload};

    print STDERR "Save attachment $filename\n" if ( $this->{debug} );

    my $tmpfile = $web . '_' . $topic . '_' . $filename;
    $tmpfile = $Foswiki::cfg{PubDir} . '/' . $tmpfile;

    $tmpfile .= 'X' while -e $tmpfile;
    open( TF, ">$tmpfile" ) || return 'Could not write ' . $tmpfile;
    print TF $attachment->{payload};
    close(TF);

    my $err = '';

    # SMELL: no central way to process attachment filenames, so we
    # have to copy-paste the Foswiki core code.
    $filename =~ s/ /_/go;
    $filename =~ s/$Foswiki::cfg{NameFilter}//goi;
    $filename =~ s/$Foswiki::cfg{UploadFilter}/$1\.txt/goi;
    Foswiki::Func::saveAttachment( $web, $topic, $filename,
        { comment => "Submitted by e-mail", file => $tmpfile } );
    unlink($tmpfile);
    return $err;
}

# Reply to a mail
sub _reply {
    my ( $this, $box, $mail, $body ) = @_;
    my $addressee =
         $mail->header('Reply-To')
      || $mail->header('From')
      || $mail->header('Return-Path');
    die "No addressee" unless $addressee;
    my $message =
        "To: $addressee"
      . "\nFrom: "
      . $mail->header('To')
      . "\nSubject: RE: your Foswiki submission to "
      . $mail->header('Subject')
      . "\n\n$body\n";
    my $errors = Foswiki::Func::sendEmail( $message, 5 );
    if ($errors) {
        print "Failed trying to send mail: $errors\n";
    }
}

1;
