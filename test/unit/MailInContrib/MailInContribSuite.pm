package MailInContribSuite;

use strict;

use Unit::TestSuite;
our @ISA = 'Unit::TestSuite';

sub name { 'MailInContribSuite' }

sub include_tests { qw(MailInContribTests MailInContribMimeTests) }

1;
