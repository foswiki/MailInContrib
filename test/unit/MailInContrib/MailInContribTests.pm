use strict;

package MailInContribTests;
use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use Foswiki;
use Error qw( :try );
use File::Path;
use Error qw( :try );
use Foswiki::Contrib::MailInContrib;

sub set_up {
    my $this = shift;

    $this->SUPER::set_up();

    $this->{system_web} = 'TemporaryMailInContribTestsSystemWeb';
    my $adm =
      Foswiki::Func::getCanonicalUserID( $Foswiki::cfg{AdminUserWikiName} );
    $Foswiki::Plugins::SESSION->{user} = $adm;
    Foswiki::Func::createWeb( $this->{system_web},
        $Foswiki::cfg{SystemWebName} );
    Foswiki::Func::saveTopic( $this->{system_web}, 'WebPreferences', undef,
        "" );

    # Patch the template path so we find our templates
    # Note that $Foswiki::cfg{SystemWebName} does not start with _,
    # so only the Web* topics are copied.
    # Specifically, the MailInContribTemplate topic is *not* copied.
    $Foswiki::cfg{TemplatePath} =~
      s/$Foswiki::cfg{SystemWebName}/$this->{system_web}/g;
    $Foswiki::cfg{SystemWebName} = $this->{system_web};

    $this->{session}->finish();
    $this->{session} = new Foswiki();

    my $workdir = Foswiki::Func::getWorkArea('MailInContrib');
    open( F, ">$workdir/timestamp" ) || die $!;
    print F "0\n";
    close(F);
    $this->registerUser( 'alig', 'Ally', 'Gator',    'ally@masai.mara' );
    $this->registerUser( 'mole', 'Mole', 'InnaHole', 'mole@hill.com' );
    Foswiki::Func::saveTopic( $this->{test_web}, $this->{test_topic}, undef,
        "" );

    $this->{session}->finish();
    $this->{session} = new Foswiki();
    $this->{session}->net->setMailHandler( sub { $this->sentMail(@_); } );

    $this->{MIC_box} = {};

    # Make a maildir
    my $tmp = "/tmp/mail$$";
    File::Path::mkpath("$tmp/tmp");
    File::Path::mkpath("$tmp/cur");
    File::Path::mkpath("$tmp/new");
    $this->{MIC_box}->{folder} = "$tmp/";

    $Foswiki::cfg{MailInContrib} = [ $this->{MIC_box} ];
    $this->{MIC_mails} = [];
}

sub tear_down {
    my $this = shift;

    $this->removeWebFixture( $this->{session}, $this->{system_web} );
    File::Path::rmtree( $this->{MIC_box}->{folder} );
    delete $this->{MIC_mails};
    delete $this->{MIC_box};
    $this->{session}->net->setMailHandler( sub { return undef } );
    $this->SUPER::tear_down();
}

sub sendTestMail {
    my ( $this, $mail ) = @_;
    my $nbr = 1;

    # Generates unique filenames for the mail files in the maildir
    # "new mail" directory.
    #
    # On an ext3 filesystem (and possibly others, too) Perl's readdir
    # returns files in hash order. The hash is created from the filename
    # and a "secret" that is different for each individual filesystem.
    # So the hash order for a fixed set of filenames varies from
    # computer to computer, but is consistent on each computer.
    # Putting the process ID in the filename should make the hash order
    # vary from run to run on an ext3 filesystem, thus eliminating
    # accidental dependence on properties that vary between computers.
    while ( -f "$this->{MIC_box}->{folder}new/mail" . $$ . $nbr ) {
        $nbr++;
    }
    open( F, ">$this->{MIC_box}->{folder}new/mail" . $$ . $nbr );
    print F $mail;
    close(F);
}

sub expectedMailOrder {
    my $this = shift;

# This function reads the list of files in the maildir directory using readdir
# to determine the order in which Email::Folder will return the mail messages
#
# ASSUMPTION : Email::Folder::Maildir uses readdir to get a list of files
# in the maildir directory.
#
# This is true for the version packaged with Email::Folder 0.855
#
# ASSUMPTION : For a given set of filenames in a given directory,
# on a given filesystem, readdir ALWAYS returns the files in the same order.
# It is assumed that this holds for ALL TYPES OF FILESYSTEM.
#
# The order MAY differ between different types of filesystem and between
# different filesystems of the same type (and therefore also between computers).
    local *DIR;
    my @order;
    opendir( DIR, "$this->{MIC_box}->{folder}new" )
      or
      $this->assert( 0, "Could not open '$this->{MIC_box}->{folder}new': $!" );
    foreach my $file ( readdir DIR ) {
        next if $file =~ /^\./;    # as suggested by DJB
        $file =~ s/^mail$$(\d+)$//
          or $this->assert( 0,
"Mail file '$file' in $this->{MIC_box}->{folder}new has the wrong format"
          );
        push @order, $1;
    }
    return @order;
}

# called from the closure which is the callback used by Net.pm
sub sentMail {
    my ( $this, $net, $mess ) = @_;
    push( @{ $this->{MIC_mails} }, $mess );
    return undef;
}

sub cron {
    my $this = shift;
    my $min = new Foswiki::Contrib::MailInContrib( $this->{session}, 0 );
    $min->processInbox( $this->{MIC_box} );
    $min->wrapUp();
    return $min;
}

sub testBadUserFetch {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.$this->{test_topic}\@example.com
Subject: $this->{test_web}.NotHere
From: notauser\@example.com

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    my $c = $this->cron();
    $this->assert_str_equals(
        'Could not determine submitters WikiName from
From: notauser@example.com
and there is no valid default username', $c->{error}
    );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( $t !~ /\S/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testAlreadyProcessedMessageReceived {
    my $this = shift;

    my $c = $this->cron();   # Set the working-dir timestamp to the current time

    my $mail = <<HERE;
Message-ID: message1
Received: by zproxy.gmail.com with SMTP id x7so839218nzc
        for <cc\@c-dot.co.uk>; Mon, 27 Feb 2006 00:34:00 -0800 (PST)
Received: from zproxy.gmail.com ([64.233.162.200])
      by ptb-mxcore01.plus.net with esmtp (PlusNet MXCore v2.00) id 1FDdpR-0003Rc-JG 
      for cc\@c-dot.co.uk; Mon, 11 Jul 2013 12:13:14 +0000
Reply-To: sender2\@example.com
To: "$this->{test_topic} $this->{test_web}" <$this->{test_web}.$this->{test_topic}\@example.com>
Subject: $this->{test_web}.IgnoreThis
From: ally\@masai.mara

Valid message headers but with a Received headers older than the timestamp
which should be ignored because MailInContrib looks for the newest Received
header.
HERE

    # Sanity check the year
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);
    $year += 1900;
    $year < 2106
      or $this->assert( 0,
            "Please change the year of the '11 Jul' date in the test"
          . "to be at least a year in the future" );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );
    $this->assert( $t !~ /\S/, $t );

    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    $c = $this->cron();
    $this->assert_null( $c->{error} );

    ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );
    $this->assert( $t !~ /\S/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testAlreadyProcessedMessageDate {
    my $this = shift;

    my $c = $this->cron();   # Set the working-dir timestamp to the current time

    my $mail = <<HERE;
Message-ID: message1
Date: Mon, 27 Feb 2006 00:33:58 -0800
Reply-To: sender2\@example.com
To: "$this->{test_topic} $this->{test_web}" <$this->{test_web}.$this->{test_topic}\@example.com>
Subject: $this->{test_web}.IgnoreThis
From: ally\@masai.mara

Valid message headers 
but with a Date header older than timestamp
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( $t !~ /\S/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testNotYetProcessedMessageDate {
    my $this = shift;

    my $c = $this->cron();   # Set the working-dir timestamp to the current time

    # Get the time of 2 minutes from now.
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      gmtime( time + 2 * 60 );
    $year += 1900;
    my @abbrMon  = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my @abbrWday = qw( Sun Mon Tue Wed Thu Fri Sat );
    foreach ( $hour, $min, $sec ) {

        # Add a leading zero, if needed
        $_ = sprintf( "%02d", $_ );
    }

    my $mail = <<HERE;
Message-ID: message1
Date: $abbrWday[$wday], $mday $abbrMon[$mon] $year $hour:$min:$sec +0000
Reply-To: sender2\@example.com
To: "$this->{test_topic} $this->{test_web}" <$this->{test_web}.$this->{test_topic}\@example.com>
Subject: $this->{test_web}.IgnoreThis
From: ally\@masai.mara

Valid message headers
but with a Date header newer than the timestamp
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~ s/^\s*\*\s+\*$this->{test_web}\.IgnoreThis\*:\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^Valid message headers\nbut with a Date header newer than the timestamp\s*//s;
    $this->assert( 0, $t )
      unless $t =~
      s/_$this->{users_web}.AllyGator \@\s+\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//m;

    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testIgnoreMessageTime {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message1
Date: Mon, 27 Feb 2006 00:33:58 -0800
Reply-To: sender1\@example.com
To: $this->{test_web}.$this->{test_topic}\@example.com
Subject: $this->{test_web}.NotHere
From: mole\@hill.com

Date header is before timestamp
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath}         = 'to';
    $this->{MIC_box}->{ignoreMessageTime} = 1;
    my $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~ s/^\s*\*\s+\*$this->{test_web}\.NotHere\*:\s*//s;
    $this->assert( 0, $t )
      unless $t =~ s/^Date header is before timestamp\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.MoleInnaHole\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_\s*//s;

    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

# topicPath to and subject
sub testSimpleTopicPathTo {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.$this->{test_topic}\@example.com
Subject: $this->{test_web}.NotHere
From: mole\@hill.com

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    my $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~ s/^\s*\*\s+\*$this->{test_web}\.NotHere\*:\s*//s;
    $this->assert( 0, $t )
      unless $t =~ s/^Message 1 text here\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.MoleInnaHole\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_\s*//s;

    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testSimpleTopicPathToCC {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.NotHere\@example.com
CC: $this->{test_web}.$this->{test_topic}\@example.com
Subject: $this->{test_web}.NotHere
From: mole\@hill.com

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    my $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~ s/^\s*\*\s+\*$this->{test_web}\.NotHere\*:\s*//s;
    $this->assert( 0, $t )
      unless $t =~ s/^Message 1 text here\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.MoleInnaHole\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_\s*//s;

    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testQuotedNameTopicPathTo {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message2
Reply-To: sender2\@example.com
To: "$this->{test_topic} $this->{test_web}" <$this->{test_web}.$this->{test_topic}\@example.com>
Subject: $this->{test_web}.IgnoreThis
From: ally\@masai.mara

Message 2 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    my $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~ s/^ *\* \*$this->{test_web}\.IgnoreThis\*: //s;
    $this->assert( 0, $t )
      unless $t =~ s/^Message 2 text here\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.AllyGator\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//s;

    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testDoubleTopicPathTo {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.$this->{test_topic}\@example.com
Subject: $this->{test_web}.NotHere
From: mole\@hill.com

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $mail = <<HERE;
Message-ID: message2
Reply-To: sender2\@example.com
To: "$this->{test_topic} $this->{test_web}" <$this->{test_web}.$this->{test_topic}\@example.com>
Subject: $this->{test_web}.IgnoreThis
From: ally\@masai.mara

Message 2 text here
HERE
    $this->sendTestMail($mail);
    my @messageOrder = $this->expectedMailOrder();
    $this->{MIC_box}->{topicPath} = 'to';
    my $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    for my $messageNumber (@messageOrder) {
        if ( $messageNumber == 1 ) {
            $this->assert( 0, $t )
              unless $t =~ s/^\s*\*\s+\*$this->{test_web}\.NotHere\*:\s*//s;
            $this->assert( 0, $t )
              unless $t =~ s/^Message 1 text here\s*//s;
            $this->assert( 0, $t )
              unless $t =~
s/^_$this->{users_web}\.MoleInnaHole\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_\s*//s;
        }
        elsif ( $messageNumber == 2 ) {
            $this->assert( 0, $t )
              unless $t =~ s/^ *\* \*$this->{test_web}\.IgnoreThis\*: //s;
            $this->assert( 0, $t )
              unless $t =~ s/^Message 2 text here\s*//s;
            $this->assert( 0, $t )
              unless $t =~
s/^_$this->{users_web}\.AllyGator\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//s;
        }
        else {
            $this->assert( 0, "Unexpected message number $messageNumber" );
        }
    }

    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testTopicPathOnlyWebTopicInSubject {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.NotHere\@example.com
Subject: $this->{test_web}.$this->{test_topic}
From: mole\@hill.com

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'subject';
    my $c = $this->cron();
    if ( $c->{error} ) {
        print STDERR $c->{error}, "\n";
        $this->assert_null( $c->{error} );
    }

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~
s/^\s*\* \*$this->{test_web}.$this->{test_topic}\*: Message 1 text here\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.MoleInnaHole\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//s;
    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testTopicPathExtraTextInSubject {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message2
Reply-To: sender2\@example.com
To: "$this->{test_topic} IgnoreThis" <$this->{test_web}.IgnoreThis\@example.com>
Subject: $this->{test_web}.$this->{test_topic}: SPAM
From: ally\@masai.mara

Message 2 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'subject';
    my $c = $this->cron();
    if ( $c->{error} ) {
        print STDERR $c->{error}, "\n";
        $this->assert_null( $c->{error} );
    }

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~
s/^\s*\*\s*\*$this->{test_web}.$this->{test_topic}: SPAM\*: Message 2 text here\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.AllyGator\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//s;
    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testTopicPathSubjectRemoveTopicFromSubject {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message2
Reply-To: sender2\@example.com
To: "$this->{test_topic} IgnoreThis" <$this->{test_web}.IgnoreThis\@example.com>
Subject: $this->{test_web}.$this->{test_topic}: SPAM
From: ally\@masai.mara

Message 2 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath}              = 'subject';
    $this->{MIC_box}->{removeTopicFromSubject} = 1;
    my $c = $this->cron();
    if ( $c->{error} ) {
        print STDERR $c->{error}, "\n";
        $this->assert_null( $c->{error} );
    }

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~ s/^\s*\*\s*\*SPAM\*: Message 2 text here\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.AllyGator\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//s;
    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testTopicPathExtraTextNoWebInSubject {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message3
Reply-To: sender3\@example.com
To: "$this->{test_topic} IgnoreThis" <NoSuch$this->{test_web}.IgnoreThis\@example.com>
Subject: $this->{test_topic}: SPAM
From: ally\@masai.mara

Message 3 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath}  = 'subject';
    $this->{MIC_box}->{defaultWeb} = $this->{test_web};
    my $c = $this->cron();
    if ( $c->{error} ) {
        print STDERR $c->{error}, "\n";
        $this->assert_null( $c->{error} );
    }

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~
      s/^\s*\*\s*\*$this->{test_topic}: SPAM\*: Message 3 text here\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.AllyGator\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//s;
    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testTopicPathSubjectToFallthru {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message3
Reply-To: sender3\@example.com
To: "$this->{test_web}.IgnoreThis$this->{test_topic} IgnoreThis" <NoSuch$this->{test_web}.IgnoreThis$this->{test_topic}\@example.com>
Subject: $this->{test_web}.$this->{test_topic}: SPAM
From: ally\@masai.mara

Message 4 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to subject';
    my $c = $this->cron();
    if ( $c->{error} ) {
        print STDERR $c->{error}, "\n";
        $this->assert_null( $c->{error} );
    }

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, $this->{test_topic} );

    $this->assert( 0, $t )
      unless $t =~
s/^\s*\*\s*\*$this->{test_web}.$this->{test_topic}: SPAM\*: Message 4 text here\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.AllyGator\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//s;
    $this->assert_matches( qr/^\s*$/, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

# defaultWeb set and unset
# existing and nonexisting web in mail
# existing and nonexisting topic in mail
# onNoTopic error and spam
sub testOnNoTopicSpam {
    my $this = shift;

    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.$this->{test_topic}\@example.com
Subject: no valid topic
From: ally\@masai.mara

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath}  = 'subject';
    $this->{MIC_box}->{onNoTopic}  = 'spam';
    $this->{MIC_box}->{spambox}    = $this->{test_web} . '.DangleBerries';
    $this->{MIC_box}->{defaultWeb} = "NotThe$this->{test_web}";
    my $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, 'DangleBerries' );

    $this->assert( $t =~ s/^\s*\* \*no valid topic\*: Message 1 text here$//m,
        $t );
    $this->assert(
        $t =~
s/_$this->{users_web}.AllyGator \@\s+\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//m,
        $t
    );
    $this->assert_matches( qr/^\s*$/s, $t );
    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub testOnErrorReplyDelete {
    my $this = shift;
    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.$this->{test_topic}\@example.com
Subject: $this->{test_web}.NotHere
From: notauser\@example.com

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    $this->{MIC_box}->{onError}   = 'reply delete';
    my $c = $this->cron();
    $this->assert_equals( 1, scalar( @{ $this->{MIC_mails} } ) );
}

sub testOnSuccessReplyDelete {
    my $this = shift;
    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.$this->{test_topic}\@example.com
Subject: $this->{test_web}.NotHere
From: mole\@hill.com

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    $this->{MIC_box}->{topicPath} = 'to';
    $this->{MIC_box}->{onSuccess} = 'reply delete';
    my $c = $this->cron();
    $this->assert_null( $c->{error} );
    $this->assert_equals( 1, scalar( @{ $this->{MIC_mails} } ) );
    $this->assert_matches( qr/Thank you for your successful/,
        $this->{MIC_mails}->[0] );
}

# attachments
sub testAttachments {
    my $this = shift;
    my $mail = <<'HERE';
From - Mon Feb 27 08:40:01 2006
X-Account-Key: account2
X-UIDL: UID7045-1090580229
X-Mozilla-Status: 0013
X-Mozilla-Status2: 10000000
Envelope-to: cc@c-dot.co.uk
Delivery-date: Mon, 27 Feb 2006 08:34:02 +0000
Received: from zproxy.gmail.com ([64.233.162.200])
	  by ptb-mxcore01.plus.net with esmtp (PlusNet MXCore v2.00) id 1FDdpR-0003Rc-JG 
	  for cc@c-dot.co.uk; Mon, 27 Feb 2006 08:34:01 +0000
Received: by zproxy.gmail.com with SMTP id x7so839218nzc
        for <cc@c-dot.co.uk>; Mon, 27 Feb 2006 00:34:00 -0800 (PST)
DomainKey-Signature: a=rsa-sha1; q=dns; c=nofws;
        s=beta; d=gmail.com;
        h=received:message-id:date:from:to:subject:cc:in-reply-to:mime-version:content-type:references;
        b=cxY2+pezI7PttYzGXPgPOekRgntHb6K0YOsnox0cfENpECsDtmx8aD/LQOfp/A2WkCQ0ZE3SEy7j62MALKeca/46SqPYg3PhIKKH03o/4NJC2zsNypKFjH3y0lV1Gy+tOqxUm5Ej2b7TgPGhmRMGWteSl+4Y235naR6WzJUxA4w=
Received: by 10.36.250.68 with SMTP id x68mr626836nzh;
        Mon, 27 Feb 2006 00:33:59 -0800 (PST)
Received: by 10.37.20.51 with HTTP; Mon, 27 Feb 2006 00:33:58 -0800 (PST)
Message-ID: <b293fda70602270033u2665f098l872ecbc52aa8d27e@gmail.com>
Date: Mon, 27 Feb 2006 00:33:58 -0800
From: "Ally Gator" <ally@masai.mara>
To: "Dick Head" <dhead@twiki.com>
Subject: $this->{test_web}.AnotherTopic: attachment test
Cc: another.idiot@twiki.com
MIME-Version: 1.0
Content-Type: multipart/mixed; 
	boundary="----=_Part_21658_5579231.1141029238540"
References: <b293fda70302260604l31abd8bfu6fc4d5015af21061@mail.gmail.com>

------=_Part_21658_5579231.1141029238540
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline

Message text

------=_Part_21658_5579231.1141029238540
Content-Type: text/plain; name="data.asc"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="data.asc"
X-Attachment-Id: file0

LS0tLS1CRUdJTiBQR1AgUFVCTElDIEtFWSBCTE9DSy0tLS0tClZlcnNpb246IEdudVBHIHYxLjIu
NSAoR05VL0xpbnV4KQoKbVFHaUJFUUN0ajRSQkFDUjAwTjFlSlhZVnNQOVdJUG1paHNwVSswb2ov
a0NIUXBkNmxQT0U5T2RYdW0vczAwUQo4b0kvUFo0WlJHYzI4YUdKTUpzZnZUaENEVkFmcE0zQXUr
SmJMQWR6NVZtdjFXdExReGdyTUI5MjZSaGlsR0FsCmRsQkJvTDhTL1FIZzNBZGpreDlrSVJxWUto
ZGpjODJLbGcvYm1LUnpxalMxZzJiaHhvVDB4emRTa3dDZzJhdk4KaE9DTG1UU3lwd2xhTUxVTUJ4
YjlUdFVELzF0L1BsOHgydXBzRTVyZXRscDB3K1hDMC9UZ2RHb25uTUh3VUZGSgp4UUEwbEF5WktC
UlpTcFdUYlk3Y0VWYzNXUXJBYW5UMFljWXlkd3BLbFFkVzRNSlAzNDNCbWRNZXNBSTVPcVlBClp6
SXMvNW9QZVFJZnFGcTR2aEVrR3kxbjVXUXFCNEcrNEgwWlBhcXVtK2ZqOHUzbjc0cUx5Vit2ODlS
UnpEUjEKVmtOckEvOWZTejVxTVh1aHU4TUZwcTdwYWlYSURLRk9TUWNWYUVkN1ozMDgxU3NTRzYv
SVBBbENCKzQ5SnJJLwpmRXBPU0piQ0VTTjhacVZXWDg1MHdLbzZ6RDN4QnByZUlCamVsQTZjaW9T
OG93ZFRKcDBWVmFFMmZoMWpFS3dOCmlFVzF2OTh2WFBFZ2FuVE0vNDNORlpSbmxlc0l4eVBZRU8z
UjNXTWw5Q1J6bi93dVNiUWdWMmxzYkNCT2IzSnkKYVhNZ1BIZGlibTl5Y21selFHZHRZV2xzTG1O
dmJUNklXd1FURVFJQUd3VUNSQUsyUGdZTENRZ0hBd0lERlFJRApBeFlDQVFJZUFRSVhnQUFLQ1JD
K1ZRc1ZvckxFR0tyTUFLQ2hHWHd5VTRaR1pNdGFlWHJuZDBtVW53eThqUUNmCmR2cTJwb1dzMEp1
WXlWWWJ2YjY3Qk1VaXFDaTVCQTBFUkFLNExCQVFBTmRzYnBmaHVpY2RyVXNYTWFxWWJISU8KYzJn
WDhNaVpqczYxT3llRkhhSE81a2pGQVhpZW9McFBDZm5va3NVYlpPMDVHaUVPQmZMdFY0eEc0Mnlo
NlVzNAo1R2o1WjZ5K1FYQTlLdWQ4UTBEZWlNQTN6b0tkeitFOUJRT2tkY1dPSlNjNVNHcXl1ZjRa
bW5jREp0QzJEWkIyCjdlWUhwSFpBem53UGkzemxCcnhpV0ZRbmJtL2l6Z2N5SmFNU1pDTlFYeTdz
Y09BeWJjd2tENnBnQkUrdWFwYmMKbTcyVXVmSVN3TU5yRmJ1ZnFFWGtsVVRzNjBqdnd5Y1AyRHhx
dTdJZXZ6NXc5WHp0NzlnZW5Mbi9RcXNZbFY5Vwo4eFF0OUY5SllUWndKTW41blkwRWpjdXdhR1Bj
cnNEcEtQQnp3R2xKWkNWdGx2VjU3cDZveHZHdkZENk51R1MzCkZlMTE3R0tvdm9CT3JzYVNERk5y
T0poMnZNemFWYlAzd2ZBMlFzR1AyNjg2bExiK3NpL1hlUkI3QXhZWVEzNjQKQTBjNjYzR3B6K29z
YlM3RWFZbWNiemxsbjZsL1A5R25rZDBOQUU5cjNOQmk5M3RiRlJtZG5qYW9kUHRkZ1BETgpZZFhk
OWdUN3FKcDV5aklkaG1YWURmQWU2WXNBTnV1enVMM0dHWTB1Qkk5M0ltalowWXJSQ0NubWNvc1Bv
aFpwCmljN2R1MTVQbnJwT1ZuempOSnFYYk9KdUdZZzl2Q1gwM2tndGxJUEhGYm90aG5QTlB2dm83
eXkyUC9RV2toYUoKeXhFUzBnY2JxVGtTZVF3RTVXSDA1dUV1RXdqY0JsU2VvY1duMThFMjJjQnpP
ZEdTM3ZXYkRpbVkrREo3TVh4TgpkM0NNSlZad1E1L0ZreXNKMEhTREFBTUdELzkrZ0hyalpIUVJL
TVgxajQyUTloWUluM3hzREFYSnkwK2UxTkRTCmVaVmNDclpGazBmVUYzMXR2aXlPTVBHTDZnTkF5
Y3lNWXdESklWbUg0TUcra1NBeVlyN0J2bVY0RllMUjdiVDIKMndNYStsV2F5aUpPWHRJTVpZQTBv
c3JhenJNUzdLVEUyTGJBQ1NLbnFURGZJRkpIVUJtam02UEZqQUFqWjJENQpaR0NHUlZiWldwa3NZ
bUd5OW1qSTQ0RStqa1kyczJpSEgvRER5QTVTajl1SUExYnpPUHVzbHlQZEtITkpXN1IrCnE4bnZG
VmtHamQ2eXhaRnpHUmdGODRYNFdSRGdsSGVtbEVXTzRWUlJ2dUNJTDZxR3VySGVOenJuaFg1WFM0
amwKVlFtd0dRVVNBWURZdXJiTUNuZG5xMjJWKy9td2RuWmxPTmYwNzRreFlJajI5enFrZlQwWWhK
bFlVTFY0SHA2VQpJbUp3OWdRTTlyaEp4NGFIc3l6K2lIYm15bG0rWXpsdDFDdVBUSnJsZTFWeEwz
TzV3RXlnUXRSeTI4aFB5dWJMClVWVVNBNjhxbDZ5bXhIV1pzZGdLemtmWktRMmdTQnZUaEdJZi9V
cnZvOU41OVlaWE0vWGU4Y1ZoeC9JTjNKRXQKcm9WTjVNR3pLR0VYZGMyK1lQcjlBdW01WG8ycXlK
bnF4NGxiamxNVWQvL3FvSUIwYXE3U2hpWndxamJDcG1CeAo2SlNiSC9KYjY2N0JJdm1vTlhxUTNQ
TGRjTkFBQ1hjZWk0bDIvSHNpeDZ0WEphTJUxNkJFT2lQNXFXUjlJY0ROCnRZTGhkMXk5Q1k1c3Ar
NDVCaGxYaXk2d3VzZG1LOHFybEowcURNdDFHMFJkVHJNNFh2N1p1QVhwR3hUaEc0bTIKdHZ1b1hv
aEdCQmdSQWdBR0JRSkVBcmdzQUFvSkVMNVZDeFdpc3NRWUsyd0FvSkd1aUQyTW1qRnpHU29IUGNj
YQp0RjZMQXNIcUFLQ0VPZmxQTllrYXlTVllMVkNGdzBMZnhIQytidz09Cj0rSi84Ci0tLS0tRU5E
IFBHUCBQVUJMSUMgS0VZIEJMT0NLLS0tLS0K
------=_Part_21658_5579231.1141029238540--
HERE
    $mail =~ s/\$this->{test_web}/$this->{test_web}/g;
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'subject';
    $this->{MIC_box}->{onError}   = 'reply';
    $this->{MIC_box}->{onSuccess} = 'reply';
    my $c = $this->cron();

    $this->assert_equals( 1, scalar( @{ $this->{MIC_mails} } ) );
    $this->assert_matches( qr/Thank you for your successful/,
        $this->{MIC_mails}->[0] );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, 'AnotherTopic' );
    my @a = $m->find('FILEATTACHMENT');
    $this->assert_equals( 1, scalar(@a) );
    $this->assert_str_equals( "data.asc", $a[0]->{attachment} );

    $this->assert(
        -e "$Foswiki::cfg{PubDir}/$this->{test_web}/AnotherTopic/data.asc" );
}

# templates

sub testUserTemplate {
    my $this = shift;
    my $mail = <<HERE;
Message-ID: message1
Reply-To: sender1\@example.com
To: $this->{test_web}.TargetTopic\@example.com
Subject: Object
From: mole\@hill.com

Message 1 text here
HERE
    $this->sendTestMail($mail);
    $this->{MIC_box}->{topicPath} = 'to';
    $this->{MIC_box}->{onSuccess} = 'reply delete';
    Foswiki::Func::saveTopic( $Foswiki::cfg{SystemWebName},
        'MailInContribUserTemplate', undef, <<'HERE');
%TMPL:DEF{MAILIN:wierd}%
Subject: %SUBJECT%
Body: %TEXT%
ID: %MAILHEADER{"Message-ID"}%
%TMPL:END%
HERE
    Foswiki::Func::saveTopic( $this->{test_web}, 'TargetTopic', undef,
        <<'HERE');

BEGIN
<!--MAIL{template="wierd" where="above"}-->
END
HERE

    my $c = $this->cron();
    $this->assert_null( $c->{error} );
    $this->assert_equals( 1, scalar( @{ $this->{MIC_mails} } ) );
    $this->assert_matches( qr/Thank you for your successful/,
        $this->{MIC_mails}->[0] );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, 'TargetTopic' );
    $this->assert_matches(
qr/BEGIN\s*Subject: Object\s*Body: Message 1 text here\s*ID: message1\s*<!--MAIL{/s,
        $t
    );
}

1;
