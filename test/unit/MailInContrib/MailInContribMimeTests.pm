use strict;

package MailInContribMimeTests;
use MailInContribTests;
our @ISA = qw( MailInContribTests );

use Foswiki;
use Error qw( :try );
use File::Path;
use Error qw( :try );
use Foswiki::Contrib::MailInContrib;

my $plainTextMessageNoMimeHeaders = <<'HERE';
From magic@thudisk.org Thu Jan 28 20:51:23 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 20:51:23 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaZSd-00068L-5w
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 20:51:23 +0200
Subject: $this->{test_web}.AnotherTopic: Plain Text
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 20:51:15 +0200
User-Agent: Opera Mail/10.10 (Win32)

Dear Bill

Please come to my party on Friday morning. Be sure to bring a friend. I  
just found lovely dot-matrix printer and I would love to show it off, so  
please bring a good program to print out. I know you have such beautiful  
code!

#include <stdlib.h>
#define PROBABILITY_OF_SUCCESS 0.5
int
main (void)
{
  if (rand() > PROBABILITY_OF_SUCCESS) 
    return 1; // failure
  return 0; // success
}

hugs and kisses
Judy
#include <stddisclaimer.h>
HERE

my $plainTextMessage = <<'HERE';
From magic@thudisk.org Thu Jan 28 20:51:23 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 20:51:23 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaZSd-00068L-5w
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 20:51:23 +0200
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Subject: $this->{test_web}.AnotherTopic: Plain Text
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 20:51:15 +0200
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Message-ID: <op.u69answxmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

Dear Bill

Please come to my party on Friday morning. Be sure to bring a friend. I  
just found lovely dot-matrix printer and I would love to show it off, so  
please bring a good program to print out. I know you have such beautiful  
code!

#include <stdlib.h>
#define PROBABILITY_OF_SUCCESS 0.5
int
main (void)
{
  if (rand() > PROBABILITY_OF_SUCCESS) 
    return 1; // failure
  return 0; // success
}

hugs and kisses
Judy
#include <stddisclaimer.h>
HERE

my $plainTextMessageWithImageAttached = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:06:53 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:06:53 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaZhc-0006Gj-Op
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:06:52 +0200
Content-Type: multipart/mixed; boundary=----------9VMjtYMKvFNX1uth9u6mzC
Subject: $this->{test_web}.AnotherTopic: Plain Text with image attached
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "Major Dolt" <dolt@purple.net>
Date: Thu, 28 Jan 2010 21:06:47 +0200
MIME-Version: 1.0
Message-ID: <op.u69bdliqmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------9VMjtYMKvFNX1uth9u6mzC
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------9VMjtYMKvFNX1uth9u6mzC
Content-Disposition: attachment; filename=za.png
Content-Type: image/png; name=za.png
Content-Transfer-Encoding: Base64

iVBORw0KGgoAAAANSUhEUgAAABAAAAALCAIAAAD5gJpuAAAABGdBTUEAAK/INwWK
6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAIUSURBVHja
YmBoFWZo5ffeX37z4unP6up/GRgg6DcDw08Ghu8MDF8ZGD4zMHxkYHjPwPCWgQEg
gBgbDzP8Yp3C8O+PuJB0kJit6N4jLEePMfz9/f/PH4Y/f/7/BjHg5JdNmwACiMXo
BoNZ+OfaM18ePnx56sXlcodE1W9fWI6d/v/gHkjdr9//f//6/+sXkM0oK/uPgQEg
AAAxAM7/AQAAAMnBfiEn6oPXCuf4BP3993MxaCQGDxLe5v/19f/+/v/+/f/9/v/+
/gEJCvGrqwIIpKGsrExH44WDLcPEB5xP/7C++/Xz738GDmaOv//+/P4LQSA3yfCI
b5g0ESCAWIAa/vz5u3Hr19fvmcv8vnfe53j9j+vHn2+fP7/49ff3r7+/gKp//fsN
1Mb+9yfDCwaAAAJp+Pv3j5sTk7P9v9kP2B78ZP3x5+uf//+4uIXZ/v4Dmf33zx+g
hn9/eLhEGHgYAAIIpMHfnVFDl7HjJvelzyy/fn2dbFPPzcT95i73ty9///4F++If
0Bf/eLhZZNTSAAKIZX4zg7oZS+5Jvjdf/zCw/i42Sdi9nHXz2vcvXj8DGgsOpH9A
K4BIRYXz4sVdAAHE8s+LoeYiNxcTs4W8aJiU/455nGfOfeHmY5Dn4gS54w8wAv4B
7fn7F0gCXfMPIIAYGTKBvmYQt7CuE5iQHfyKAegvhn9g9AvG+ANGDGCSDSDAAOBC
Ll8bj6ZDAAAAAElFTkSuQmCC

------------9VMjtYMKvFNX1uth9u6mzC--

HERE

my $plainTextMessageWithTextAttached = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:11:25 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:11:25 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaZm0-0006J2-VA
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:11:25 +0200
Content-Type: multipart/mixed; boundary=----------Wq3Fb7J0RE2crjsFpgh1Zk
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Subject: $this->{test_web}.AnotherTopic: Plain Text with text attached
Auto-Submitted: auto-generated
Date: Thu, 28 Jan 2010 21:11:20 +0200
MIME-Version: 1.0
Message-ID: <op.u69bk6swmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------Wq3Fb7J0RE2crjsFpgh1Zk
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------Wq3Fb7J0RE2crjsFpgh1Zk
Content-Disposition: attachment; filename=plain.txt
Content-Type: text/plain; name=plain.txt
Content-Transfer-Encoding: 7bit

This is
 a plain
text file!

------------Wq3Fb7J0RE2crjsFpgh1Zk--

HERE

my $plainTextMessageWithHtmlAttached = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:30:56 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:30:56 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1Naa4u-0006Rk-OS
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:30:56 +0200
Content-Type: multipart/mixed; boundary=----------tn4G2p9YnqHHx0HfiDh0Jj
Subject: $this->{test_web}.AnotherTopic: Plain Text with HTML attachment
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 21:30:52 +0200
MIME-Version: 1.0
Message-ID: <op.u69chqdtmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------tn4G2p9YnqHHx0HfiDh0Jj
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------tn4G2p9YnqHHx0HfiDh0Jj
Content-Disposition: attachment; filename=simple.html
Content-Type: text/html; name=simple.html
Content-Transfer-Encoding: 7bit

<html>
  <head>
    <title>This is the Title</title>
    <style type="text/css">
      body {
        background-color: #e0e0e0;
        color: #3050a0;
        font-family: sans-serif;
      }
    </style>
  </head>
  <body style="font-weight: bold">
    <p style="text-decoration: underline">
    So much <em>Wonder</em>!
    </p>
  </body>
</html>

------------tn4G2p9YnqHHx0HfiDh0Jj--

HERE

my $plainTextMessageContainingHtml = <<'HERE';
From magic@thudisk.org Thu Jan 28 20:51:23 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 20:51:23 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaZSd-00068L-5w
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 20:51:23 +0200
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Subject: $this->{test_web}.AnotherTopic: Html As Plain Text
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 20:51:15 +0200
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Message-ID: <op.u69answxmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD></HEAD>
<BODY style=3D"font-size:13px"><DIV><FONT face="Georgia">
We have the Cape of Good Hope 
</FONT><IMG src="cid:za.png@12=64707563.8aee617a41d2bf17">
<EM>but we seem to have misplaced the superhero it came with.</EM>

<img src="http://foswiki.org/pub/System/FoswikiSiteSkin/pencil.gif" alt="">

<script>Hey - this isn't javascript, it is plain text</script>

</DIV></BODY></HTML>
HERE

my $htmlWithTextMessage = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:38:14 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:38:14 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaaBy-0006VE-3e
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:38:14 +0200
Content-Type: multipart/alternative; boundary=----------9CL0w9YQnQWV1xj9ZEirtx
Subject:
 $this->{test_web}.AnotherTopic:
 HTML
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 21:38:09 +0200
MIME-Version: 1.0
Message-ID: <op.u69ctvmdmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------9CL0w9YQnQWV1xj9ZEirtx
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------9CL0w9YQnQWV1xj9ZEirtx
Content-Type: multipart/related; boundary=----------9CL0w9YQnQWV1xyG7rilDq

------------9CL0w9YQnQWV1xyG7rilDq
Content-Type: text/html; charset=iso-8859-15
Content-ID: <op.1264707489187.5f8f6d546d5d5d13@172.16.19.1>
Content-Transfer-Encoding: Quoted-Printable

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD><STYLE type="text/css">BODY { color:#3050a0; }</STYLE></HEAD>
<BODY style=3D"font-weight:bold"><DIV><FONT face=3D"G=
eorgia">Mar<em>mel</em>ade</FONT></DIV></BODY></HTML>
------------9CL0w9YQnQWV1xyG7rilDq--

------------9CL0w9YQnQWV1xj9ZEirtx--

HERE

my $htmlWithTextMessageWithInlineImage = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:42:37 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:42:37 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaaGD-0006XH-Hv
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:42:37 +0200
Content-Type: multipart/alternative; boundary=----------MOQa6apUY61ka2jxRHU07U
Subject: $this->{test_web}.AnotherTopic: HTML with inline image
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 21:42:32 +0200
MIME-Version: 1.0
Message-ID: <op.u69c06tfmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------MOQa6apUY61ka2jxRHU07U
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------MOQa6apUY61ka2jxRHU07U
Content-Type: multipart/related; boundary=----------MOQa6apUY61ka2OuTr2flQ

------------MOQa6apUY61ka2OuTr2flQ
Content-Type: text/html; charset=iso-8859-15
Content-ID: <op.1264707752578.197b7d546d5d5d13@172.16.19.1>
Content-Transfer-Encoding: Quoted-Printable

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD></HEAD>
<BODY style=3D"font-size:13px"><DIV><FONT face=3D"G=
eorgia">We have the Cape of Good Hope </FONT><IMG src=3D"cid:za.png@12=
64707563.8aee617a41d2bf17"> <EM>but we seem to have misplaced the superh=
ero it came with.</EM></DIV></BODY></HTML>
------------MOQa6apUY61ka2OuTr2flQ
Content-Disposition: inline
Content-Type: image/png
Content-ID: <za.png@1264707563.8aee617a41d2bf17>
Content-Transfer-Encoding: Base64

iVBORw0KGgoAAAANSUhEUgAAABAAAAALCAIAAAD5gJpuAAAABGdBTUEAAK/INwWK
6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAIUSURBVHja
YmBoFWZo5ffeX37z4unP6up/GRgg6DcDw08Ghu8MDF8ZGD4zMHxkYHjPwPCWgQEg
gBgbDzP8Yp3C8O+PuJB0kJit6N4jLEePMfz9/f/PH4Y/f/7/BjHg5JdNmwACiMXo
BoNZ+OfaM18ePnx56sXlcodE1W9fWI6d/v/gHkjdr9//f//6/+sXkM0oK/uPgQEg
AAAxAM7/AQAAAMnBfiEn6oPXCuf4BP3993MxaCQGDxLe5v/19f/+/v/+/f/9/v/+
/gEJCvGrqwIIpKGsrExH44WDLcPEB5xP/7C++/Xz738GDmaOv//+/P4LQSA3yfCI
b5g0ESCAWIAa/vz5u3Hr19fvmcv8vnfe53j9j+vHn2+fP7/49ff3r7+/gKp//fsN
1Mb+9yfDCwaAAAJp+Pv3j5sTk7P9v9kP2B78ZP3x5+uf//+4uIXZ/v4Dmf33zx+g
hn9/eLhEGHgYAAIIpMHfnVFDl7HjJvelzyy/fn2dbFPPzcT95i73ty9///4F++If
0Bf/eLhZZNTSAAKIZX4zg7oZS+5Jvjdf/zCw/i42Sdi9nHXz2vcvXj8DGgsOpH9A
K4BIRYXz4sVdAAHE8s+LoeYiNxcTs4W8aJiU/455nGfOfeHmY5Dn4gS54w8wAv4B
7fn7F0gCXfMPIIAYGTKBvmYQt7CuE5iQHfyKAegvhn9g9AvG+ANGDGCSDSDAAOBC
Ll8bj6ZDAAAAAElFTkSuQmCC

------------MOQa6apUY61ka2OuTr2flQ--

------------MOQa6apUY61ka2jxRHU07U--

HERE

my $htmlWithTextMessageWithAttachedImage = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:45:18 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:45:18 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaaIo-0006Yj-Mp
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:45:18 +0200
Content-Type: multipart/mixed; boundary=----------jNngAQGNgFFTjLJaCpAlcI
Subject: $this->{test_web}.AnotherTopic: HTML with image attached
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 21:45:14 +0200
MIME-Version: 1.0
Message-ID: <op.u69c5oi4mjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------jNngAQGNgFFTjLJaCpAlcI
Content-Type: multipart/alternative; boundary=----------jNngAQGNgFFTjL6yrKhFD4

------------jNngAQGNgFFTjL6yrKhFD4
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------jNngAQGNgFFTjL6yrKhFD4
Content-Type: multipart/related; boundary=----------jNngAQGNgFFTjLiLq8NtNp

------------jNngAQGNgFFTjLiLq8NtNp
Content-Type: text/html; charset=iso-8859-15
Content-ID: <op.1264707914000.12c25d546d5d5d13@172.16.19.1>
Content-Transfer-Encoding: Quoted-Printable

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD><STYLE type="text/css">BODY { color:#3050a0; }</STYLE></HEAD>
<BODY style=3D"font-weight:bold"><DIV><FONT face=3D"G=
eorgia">Mar<em>mel</em>ade</FONT></DIV></BODY></HTML>
------------jNngAQGNgFFTjLiLq8NtNp--

------------jNngAQGNgFFTjL6yrKhFD4--

------------jNngAQGNgFFTjLJaCpAlcI
Content-Disposition: attachment; filename=za.png
Content-Type: image/png; name=za.png
Content-Transfer-Encoding: Base64

iVBORw0KGgoAAAANSUhEUgAAABAAAAALCAIAAAD5gJpuAAAABGdBTUEAAK/INwWK
6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAIUSURBVHja
YmBoFWZo5ffeX37z4unP6up/GRgg6DcDw08Ghu8MDF8ZGD4zMHxkYHjPwPCWgQEg
gBgbDzP8Yp3C8O+PuJB0kJit6N4jLEePMfz9/f/PH4Y/f/7/BjHg5JdNmwACiMXo
BoNZ+OfaM18ePnx56sXlcodE1W9fWI6d/v/gHkjdr9//f//6/+sXkM0oK/uPgQEg
AAAxAM7/AQAAAMnBfiEn6oPXCuf4BP3993MxaCQGDxLe5v/19f/+/v/+/f/9/v/+
/gEJCvGrqwIIpKGsrExH44WDLcPEB5xP/7C++/Xz738GDmaOv//+/P4LQSA3yfCI
b5g0ESCAWIAa/vz5u3Hr19fvmcv8vnfe53j9j+vHn2+fP7/49ff3r7+/gKp//fsN
1Mb+9yfDCwaAAAJp+Pv3j5sTk7P9v9kP2B78ZP3x5+uf//+4uIXZ/v4Dmf33zx+g
hn9/eLhEGHgYAAIIpMHfnVFDl7HjJvelzyy/fn2dbFPPzcT95i73ty9///4F++If
0Bf/eLhZZNTSAAKIZX4zg7oZS+5Jvjdf/zCw/i42Sdi9nHXz2vcvXj8DGgsOpH9A
K4BIRYXz4sVdAAHE8s+LoeYiNxcTs4W8aJiU/455nGfOfeHmY5Dn4gS54w8wAv4B
7fn7F0gCXfMPIIAYGTKBvmYQt7CuE5iQHfyKAegvhn9g9AvG+ANGDGCSDSDAAOBC
Ll8bj6ZDAAAAAElFTkSuQmCC

------------jNngAQGNgFFTjLJaCpAlcI--

HERE

my $htmlWithTextMessageWithTextAttached = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:50:45 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:50:45 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaaO4-0006cJ-W5
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:50:45 +0200
Content-Type: multipart/mixed; boundary=----------Ky64u8Y5DfkBons6rsWaZz
Subject: $this->{test_web}.AnotherTopic: HTML with text attachment
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 21:50:40 +0200
MIME-Version: 1.0
Message-ID: <op.u69deqkgmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------Ky64u8Y5DfkBons6rsWaZz
Content-Type: multipart/alternative; boundary=----------Ky64u8Y5DfkBonvC044JyN

------------Ky64u8Y5DfkBonvC044JyN
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------Ky64u8Y5DfkBonvC044JyN
Content-Type: multipart/related; boundary=----------Ky64u8Y5DfkBon33cJlYdF

------------Ky64u8Y5DfkBon33cJlYdF
Content-Type: text/html; charset=iso-8859-15
Content-ID: <op.1264708240703.9103ad546d5d5d13@172.16.19.1>
Content-Transfer-Encoding: Quoted-Printable

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD><STYLE type="text/css">BODY { color:#3050a0; }</STYLE></HEAD>
<BODY style=3D"font-weight:bold"><DIV><FONT face=3D"G=
eorgia">Mar<em>mel</em>ade</FONT></DIV></BODY></HTML>
------------Ky64u8Y5DfkBon33cJlYdF--

------------Ky64u8Y5DfkBonvC044JyN--

------------Ky64u8Y5DfkBons6rsWaZz
Content-Disposition: attachment; filename=plain.txt
Content-Type: text/plain; name=plain.txt
Content-Transfer-Encoding: 7bit

This is
 a plain
text file!

------------Ky64u8Y5DfkBons6rsWaZz--

HERE

my $htmlWithTextMessageWithHtmlAttached = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:53:31 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:53:31 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaaQl-0006di-Lg
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:53:31 +0200
Content-Type: multipart/mixed; boundary=----------og4dYcGRJjxYLBBnMP6ekf
Subject: $this->{test_web}.AnotherTopic: HTML with HTML attachment
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 21:53:27 +0200
MIME-Version: 1.0
Message-ID: <op.u69djdjfmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------og4dYcGRJjxYLBBnMP6ekf
Content-Type: multipart/alternative; boundary=----------og4dYcGRJjxYLBc6D9vQuE

------------og4dYcGRJjxYLBc6D9vQuE
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------og4dYcGRJjxYLBc6D9vQuE
Content-Type: multipart/related; boundary=----------og4dYcGRJjxYLBWlYnXbq3

------------og4dYcGRJjxYLBWlYnXbq3
Content-Type: text/html; charset=iso-8859-15
Content-ID: <op.1264708407609.bf43cd546d5d5d13@172.16.19.1>
Content-Transfer-Encoding: Quoted-Printable

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD><STYLE type="text/css">BODY { color:#3050a0; }</STYLE></HEAD>
<BODY style=3D"font-weight:bold"><DIV><FONT face=3D"G=
eorgia">Mar<em>mel</em>ade</FONT></DIV></BODY></HTML>
------------og4dYcGRJjxYLBWlYnXbq3--

------------og4dYcGRJjxYLBc6D9vQuE--

------------og4dYcGRJjxYLBBnMP6ekf
Content-Disposition: attachment; filename=simple.html
Content-Type: text/html; name=simple.html
Content-Transfer-Encoding: 7bit

<html>
  <head>
    <title>This is the Title</title>
    <style type="text/css">
      body {
        background-color: #e0e0e0;
        color: #3050a0;
        font-family: sans-serif;
      }
    </style>
  </head>
  <body style="font-weight: bold">
    <p style="text-decoration: underline">
    So much <em>Wonder</em>!
    </p>
  </body>
</html>

------------og4dYcGRJjxYLBBnMP6ekf--

HERE

my $htmlNoTextMessage = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:38:14 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:38:14 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaaBy-0006VE-3e
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:38:14 +0200
Content-Type: text/html; charset=iso-8859-15
Subject: $this->{test_web}.AnotherTopic: HTML
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 21:38:09 +0200
MIME-Version: 1.0
Message-ID: <op.u69ctvmdmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)
Content-Transfer-Encoding: Quoted-Printable
Content-ID: <op.1264707489187.5f8f6d546d5d5d13@172.16.19.1>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD><STYLE type="text/css">BODY { color:#3050a0; }</STYLE></HEAD>
<BODY style=3D"font-weight:bold"><DIV><FONT face=3D"G=
eorgia">Mar<em>mel</em>ade</FONT></DIV></BODY></HTML>
HERE

my $htmlWithScript = <<'HERE';
From magic@thudisk.org Thu Jan 28 21:38:14 2010
Return-path: <magic@thudisk.org>
Envelope-to: www-data@tou810.localdomain
Delivery-date: Thu, 28 Jan 2010 21:38:14 +0200
Received: from [172.16.225.1] (helo=michaeltempest)
	by tou810.localdomain with esmtp (Exim 4.69)
	(envelope-from <magic@thudisk.org>)
	id 1NaaBy-0006VE-3e
	for www-data@tou810.localdomain; Thu, 28 Jan 2010 21:38:14 +0200
Content-Type: multipart/alternative; boundary=----------9CL0w9YQnQWV1xj9ZEirtx
Subject:
 $this->{test_web}.AnotherTopic:
 HTML with script
Auto-Submitted: auto-generated
From: "Ally Gator" <ally@masai.mara>
To: "The Wiki" <wiki@some.company>
Date: Thu, 28 Jan 2010 21:38:09 +0200
MIME-Version: 1.0
Message-ID: <op.u69ctvmdmjv6gc@michaeltempest>
User-Agent: Opera Mail/10.10 (Win32)

------------9CL0w9YQnQWV1xj9ZEirtx
Content-Type: text/plain; charset=iso-8859-15; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit

2B, or not 2B; that is the pencil!
------------9CL0w9YQnQWV1xj9ZEirtx
Content-Type: multipart/related; boundary=----------9CL0w9YQnQWV1xyG7rilDq

------------9CL0w9YQnQWV1xyG7rilDq
Content-Type: text/html; charset=iso-8859-15
Content-ID: <op.1264707489187.5f8f6d546d5d5d13@172.16.19.1>
Content-Transfer-Encoding: Quoted-Printable

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD><STYLE type="text/css">BODY { color:#3050a0; }</STYLE></HEAD>
<BODY style=3D"font-weight:bold"><script type="text/javascript"> bl=
ah blah blah blah blah</script><DIV><FONT face=3D"G=
eorgia" onclick="hello()">Mar<em>mel</em>ade</FONT></DIV></BODY></HTML>
------------9CL0w9YQnQWV1xyG7rilDq--

------------9CL0w9YQnQWV1xj9ZEirtx--

HERE

my %expectedContent = (
    complexText => <<'HERE',
Dear Bill

Please come to my party on Friday morning. Be sure to bring a friend. I  
just found lovely dot-matrix printer and I would love to show it off, so  
please bring a good program to print out. I know you have such beautiful  
code!

#include <stdlib.h>
#define PROBABILITY_OF_SUCCESS 0.5
int
main (void)
{
  if (rand() > PROBABILITY_OF_SUCCESS) 
    return 1; // failure
  return 0; // success
}

hugs and kisses
Judy
#include <stddisclaimer.h>
HERE

    plainText => "2B, or not 2B; that is the pencil!",

    plainHtml =>
'<literal><div class="foswikiMailInContribHtml"><div style="font-weight:bold"><DIV><FONT face="Georgia">Mar<em>mel</em>ade</FONT></DIV></div></div></literal>'
      . "\n",

    inlineImageHtml =>
'<literal><div class="foswikiMailInContribHtml"><div style="font-size:13px"><DIV><FONT face="Georgia">We have the Cape of Good Hope </FONT><IMG src="%ATTACHURLPATH%/za.png"> <EM>but we seem to have misplaced the superhero it came with.</EM></DIV></div></div></literal>'
      . "\n",

    inlineImageRemovedHtml =>
'<literal><div class="foswikiMailInContribHtml"><div style="font-size:13px"><DIV><FONT face="Georgia">We have the Cape of Good Hope </FONT> <EM>but we seem to have misplaced the superhero it came with.</EM></DIV></div></div></literal>'
      . "\n",

    inlineImageMadeExternalHtml =>
'<literal><div class="foswikiMailInContribHtml"><div style="font-size:13px"><DIV><FONT face="Georgia">We have the Cape of Good Hope </FONT><IMG src="http://www.example.com/turkey.png"> <EM>but we seem to have misplaced the superhero it came with.</EM></DIV></div></div></literal>'
      . "\n",

    htmlAsPlainText => <<'HERE',
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<HTML>
<HEAD></HEAD>
<BODY style=3D"font-size:13px"><DIV><FONT face="Georgia">
We have the Cape of Good Hope 
</FONT><IMG src="cid:za.png@12=64707563.8aee617a41d2bf17">
<EM>but we seem to have misplaced the superhero it came with.</EM>

<img src="http://foswiki.org/pub/System/FoswikiSiteSkin/pencil.gif" alt="">

<script>Hey - this isn't javascript, it is plain text</script>

</DIV></BODY></HTML>
HERE

    image =>    # FamFamFamContrib's za.png
"\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00"
      . "\x10\x00\x00\x00\x0b\x08\x02\x00\x00\x00\xf9\x80\x9a\x6e\x00\x00\x00\x04\x67\x41"
      . "\x4d\x41\x00\x00\xaf\xc8\x37\x05\x8a\xe9\x00\x00\x00\x19\x74\x45\x58\x74\x53\x6f"
      . "\x66\x74\x77\x61\x72\x65\x00\x41\x64\x6f\x62\x65\x20\x49\x6d\x61\x67\x65\x52\x65"
      . "\x61\x64\x79\x71\xc9\x65\x3c\x00\x00\x02\x14\x49\x44\x41\x54\x78\xda\x62\x60\x68"
      . "\x15\x66\x68\xe5\xf7\xde\x5f\x7e\xf3\xe2\xe9\xcf\xea\xea\x7f\x19\x18\x20\xe8\x37"
      . "\x03\xc3\x4f\x06\x86\xef\x0c\x0c\x5f\x19\x18\x3e\x33\x30\x7c\x64\x60\x78\xcf\xc0"
      . "\xf0\x96\x81\x01\x20\x80\x18\x1b\x0f\x33\xfc\x62\x9d\xc2\xf0\xef\x8f\xb8\x90\x74"
      . "\x90\x98\xad\xe8\xde\x23\x2c\x47\x8f\x31\xfc\xfd\xfd\xff\xcf\x1f\x86\x3f\x7f\xfe"
      . "\xff\x06\x31\xe0\xe4\x97\x4d\x9b\x00\x02\x88\xc5\xe8\x06\x83\x59\xf8\xe7\xda\x33"
      . "\x5f\x1e\x3e\x7c\x79\xea\xc5\xe5\x72\x87\x44\xd5\x6f\x5f\x58\x8e\x9d\xfe\xff\xe0"
      . "\x1e\x48\xdd\xaf\xdf\xff\x7f\xff\xfa\xff\xeb\x17\x90\xcd\x28\x2b\xfb\x8f\x81\x01"
      . "\x20\x00\x00\x31\x00\xce\xff\x01\x00\x00\x00\xc9\xc1\x7e\x21\x27\xea\x83\xd7\x0a"
      . "\xe7\xf8\x04\xfd\xfd\xf7\x73\x31\x68\x24\x06\x0f\x12\xde\xe6\xff\xf5\xf5\xff\xfe"
      . "\xfe\xff\xfe\xfd\xff\xfd\xfe\xff\xfe\xfe\x01\x09\x0a\xf1\xab\xab\x02\x08\xa4\xa1"
      . "\xac\xac\x4c\x47\xe3\x85\x83\x2d\xc3\xc4\x07\x9c\x4f\xff\xb0\xbe\xfb\xf5\xf3\xef"
      . "\x7f\x06\x0e\x66\x8e\xbf\xff\xfe\xfc\xfe\x0b\x41\x20\x37\xc9\xf0\x88\x6f\x98\x34"
      . "\x11\x20\x80\x58\x80\x1a\xfe\xfc\xf9\xbb\x71\xeb\xd7\xd7\xef\x99\xcb\xfc\xbe\x77"
      . "\xde\xe7\x78\xfd\x8f\xeb\xc7\x9f\x6f\x9f\x3f\xbf\xf8\xf5\xf7\xf7\xaf\xbf\xbf\x80"
      . "\xaa\x7f\xfd\xfb\x0d\xd4\xc6\xfe\xf7\x27\xc3\x0b\x06\x80\x00\x02\x69\xf8\xfb\xf7"
      . "\x8f\x9b\x13\x93\xb3\xfd\xbf\xd9\x0f\xd8\x1e\xfc\x64\xfd\xf1\xe7\xeb\x9f\xff\xff"
      . "\xb8\xb8\x85\xd9\xfe\xfe\x03\x99\xfd\xf7\xcf\x1f\xa0\x86\x7f\x7f\x78\xb8\x44\x18"
      . "\x78\x18\x00\x02\x08\xa4\xc1\xdf\x9d\x51\x43\x97\xb1\xe3\x26\xf7\xa5\xcf\x2c\xbf"
      . "\x7e\x7d\x9d\x6c\x53\xcf\xcd\xc4\xfd\xe6\x2e\xf7\xb7\x2f\x7f\xff\xfe\x05\xfb\xe2"
      . "\x1f\xd0\x17\xff\x78\xb8\x59\x64\xd4\xd2\x00\x02\x88\x65\x7e\x33\x83\xba\x19\x4b"
      . "\xee\x49\xbe\x37\x5f\xff\x30\xb0\xfe\x2e\x36\x49\xd8\xbd\x9c\x75\xf3\xda\xf7\x2f"
      . "\x5e\x3f\x03\x1a\x0b\x0e\xa4\x7f\x40\x2b\x80\x48\x45\x85\xf3\xe2\xc5\x5d\x00\x01"
      . "\xc4\xf2\xcf\x8b\xa1\xe6\x22\x37\x17\x13\xb3\x85\xbc\x68\x98\x94\xff\x8e\x79\x9c"
      . "\x67\xce\x7d\xe1\xe6\x63\x90\xe7\xe2\x04\xb9\xe3\x0f\x30\x02\xfe\x01\xed\xf9\xfb"
      . "\x17\x48\x02\x5d\xf3\x0f\x20\x80\x18\x19\x32\x81\xbe\x66\x10\xb7\xb0\xae\x13\x98"
      . "\x90\x1d\xfc\x8a\x01\xe8\x2f\x86\x7f\x60\xf4\x0b\xc6\xf8\x03\x46\x0c\x60\x92\x0d"
      . "\x20\xc0\x00\xe0\x42\x2e\x5f\x1b\x8f\xa6\x43\x00\x00\x00\x00\x49\x45\x4e\x44\xae"
      . "\x42\x60\x82",

    htmlFile => <<'HERE',
<html>
  <head>
    <title>This is the Title</title>
    <style type="text/css">
      body {
        background-color: #e0e0e0;
        color: #3050a0;
        font-family: sans-serif;
      }
    </style>
  </head>
  <body style="font-weight: bold">
    <p style="text-decoration: underline">
    So much <em>Wonder</em>!
    </p>
  </body>
</html>
HERE

    textFile => <<'HERE',
This is
 a plain
text file!
HERE
);
chomp( $expectedContent{htmlFile} );
chomp( $expectedContent{textFile} );

my @tests = (
    {
        name    => 'plainTextNoMimeHeadersAsText',
        message => $plainTextMessageNoMimeHeaders,
        content => { type => 'text', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: Plain Text',
        match => { text => $expectedContent{complexText} },
    },
    {
        name    => 'plainTextNoMimeHeadersAsHtml',
        message => $plainTextMessageNoMimeHeaders,
        content => { type => 'html', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: Plain Text',
        match => { text => $expectedContent{complexText} },
    },
    {
        name    => 'plainTextAsText',
        message => $plainTextMessage,
        content => { type => 'text', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: Plain Text',
        match => { text => $expectedContent{complexText} },
    },
    {
        name    => 'plainTextAsHtml',
        message => $plainTextMessage,
        content => { type => 'html', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: Plain Text',
        match => { text => $expectedContent{complexText} },
    },
    {
        name    => 'plainTextWithAttachedImageAsText',
        message => $plainTextMessageWithImageAttached,
        content => { type => 'text', processors => [] },
        subject =>
          '$this->{test_web}.AnotherTopic: Plain Text with image attached',
        match => {
            text   => $expectedContent{plainText},
            attach => { 'za.png' => 'image' }
        },
    },
    {
        name    => 'plainTextWithAttachedImageAsHtml',
        message => $plainTextMessageWithImageAttached,
        content => { type => 'html', processors => [] },
        subject =>
          '$this->{test_web}.AnotherTopic: Plain Text with image attached',
        match => {
            text   => $expectedContent{plainText},
            attach => { 'za.png' => 'image' }
        },
    },
    {
        name    => 'plainTextWithAttachedTextAsText',
        message => $plainTextMessageWithTextAttached,
        content => { type => 'text', processors => [] },
        subject =>
          '$this->{test_web}.AnotherTopic: Plain Text with text attached',
        match => {
            text   => $expectedContent{plainText},
            attach => { 'plain.txt' => 'textFile' }
        },
    },
    {
        name    => 'plainTextWithAttachedTextAsHtml',
        message => $plainTextMessageWithTextAttached,
        content => { type => 'html', processors => [] },
        subject =>
          '$this->{test_web}.AnotherTopic: Plain Text with text attached',
        match => {
            text   => $expectedContent{plainText},
            attach => { 'plain.txt' => 'textFile' }
        },
    },
    {
        name    => 'plainTextWithAttachedHtmlAsText',
        message => $plainTextMessageWithHtmlAttached,
        content => { type => 'text', processors => [] },
        subject =>
          '$this->{test_web}.AnotherTopic: Plain Text with HTML attachment',
        match => {
            text   => $expectedContent{plainText},
            attach => { 'simple.html' => 'htmlFile' }
        },
    },
    {
        name    => 'plainTextWithAttachedHtmlAsHtml',
        message => $plainTextMessageWithHtmlAttached,
        content => { type => 'html', processors => [] },
        subject =>
          '$this->{test_web}.AnotherTopic: Plain Text with HTML attachment',
        match => {
            text   => $expectedContent{plainText},
            attach => { 'simple.html' => 'htmlFile' }
        },
    },
    {
        name    => 'alternateTextAsText',
        message => $htmlWithTextMessage,
        content => { type => 'text', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML',
        match => { text => $expectedContent{plainText} },
    },
    {
        name    => 'alternateTextAsHtml',
        message => $htmlWithTextMessage,
        content => { type => 'html', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML',
        match => { text => $expectedContent{plainHtml} },
    },
    {
        name    => 'alternateTextWithInlineImageAsText',
        message => $htmlWithTextMessageWithInlineImage,
        content => { type => 'text', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match => { text => $expectedContent{plainText} },
    },
    {
        name    => 'alternateTextWithInlineImageAsHtml',
        message => $htmlWithTextMessageWithInlineImage,
        content => { type => 'html', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => {
            text   => $expectedContent{inlineImageHtml},
            attach => { 'za.png' => 'image' }
        },
    },
    {
        name    => 'alternateTextWithAttachedImageAsText',
        message => $htmlWithTextMessageWithAttachedImage,
        content => { type => 'text', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML with image attached',
        match   => {
            text   => $expectedContent{plainText},
            attach => { 'za.png' => 'image' }
        },
    },
    {
        name    => 'alternateTextWithAttachedImageAsHtml',
        message => $htmlWithTextMessageWithAttachedImage,
        content => { type => 'html', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML with image attached',
        match   => {
            text   => $expectedContent{plainHtml},
            attach => { 'za.png' => 'image' }
        },
    },
    {
        name    => 'alternateTextWithAttachedTextAsText',
        message => $htmlWithTextMessageWithTextAttached,
        content => { type => 'text', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML with text attachment',
        match   => {
            text   => $expectedContent{plainText},
            attach => { 'plain.txt' => 'textFile' }
        },
    },
    {
        name    => 'alternateTextWithAttachedTextAsHtml',
        message => $htmlWithTextMessageWithTextAttached,
        content => { type => 'html', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML with text attachment',
        match   => {
            text   => $expectedContent{plainHtml},
            attach => { 'plain.txt' => 'textFile' }
        },
    },
    {
        name    => 'alternateTextWithAttachedHtmlAsText',
        message => $htmlWithTextMessageWithHtmlAttached,
        content => { type => 'text', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML with HTML attachment',
        match   => {
            text   => $expectedContent{plainText},
            attach => { 'simple.html' => 'htmlFile' }
        },
    },
    {
        name    => 'alternateTextWithAttachedHtmlAsHtml',
        message => $htmlWithTextMessageWithHtmlAttached,
        content => { type => 'html', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML with HTML attachment',
        match   => {
            text   => $expectedContent{plainHtml},
            attach => { 'simple.html' => 'htmlFile' }
        },
    },
    {
        name    => 'OnlyHtmlAsHtml',
        message => $htmlNoTextMessage,
        content => { type => 'html', processors => [] },
        subject => '$this->{test_web}.AnotherTopic: HTML',
        match => { text => $expectedContent{plainHtml} },
    },
    {
        name    => 'htmlWithScript',
        message => $htmlWithScript,
        content => {
            type => 'html',
            processors =>
              [ { pkg => 'Foswiki::Contrib::MailInContrib::NoScript' } ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with script',
        match   => { text => $expectedContent{plainHtml} },
    },
    {
        name    => 'htmlRemoveInlineImage',
        message => $htmlWithTextMessageWithInlineImage,
        content => {
            type => 'html',
            processors =>
              [ { pkg => 'Foswiki::Contrib::MailInContrib::NoInlineContent' } ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => { text => $expectedContent{inlineImageRemovedHtml} },
    },
    {
        name    => 'htmlInlineImageNotConsideredExternalNoDomains',
        message => $htmlWithTextMessageWithInlineImage,
        content => {
            type       => 'html',
            processors => [
                {
                    pkg =>
                      'Foswiki::Contrib::MailInContrib::FilterExternalResources'
                }
            ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => {
            text   => $expectedContent{inlineImageHtml},
            attach => { 'za.png' => 'image' }
        },
    },
    {
        name    => 'htmlInlineImageNotConsideredExternalWithDomains',
        message => $htmlWithTextMessageWithInlineImage,
        content => {
            type       => 'html',
            processors => [
                {
                    pkg =>
'Foswiki::Contrib::MailInContrib::FilterExternalResources',
                    safedomains => 'www.example.com'
                }
            ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => {
            text   => $expectedContent{inlineImageHtml},
            attach => { 'za.png' => 'image' }
        },
    },
    {
        name    => 'htmlExternalImageNotConsideredInline',
        message => _replaceInlineImageWithExternalImage(
            $htmlWithTextMessageWithInlineImage),
        content => {
            type => 'html',
            processors =>
              [ { pkg => 'Foswiki::Contrib::MailInContrib::NoInlineContent' } ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => { text => $expectedContent{inlineImageMadeExternalHtml} },
    },
    {
        name    => 'htmlExternalImageRemoved',
        message => _replaceInlineImageWithExternalImage(
            $htmlWithTextMessageWithInlineImage),
        content => {
            type       => 'html',
            processors => [
                {
                    pkg =>
                      'Foswiki::Contrib::MailInContrib::FilterExternalResources'
                }
            ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => { text => $expectedContent{inlineImageRemovedHtml} },
    },
    {
        name    => 'htmlSafeDomainExternalImageNotRemoved',
        message => _replaceInlineImageWithExternalImage(
            $htmlWithTextMessageWithInlineImage),
        content => {
            type       => 'html',
            processors => [
                {
                    pkg =>
'Foswiki::Contrib::MailInContrib::FilterExternalResources',
                    safedomains => 'www.example.com'
                }
            ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => { text => $expectedContent{inlineImageMadeExternalHtml} },
    },
    {
        name    => 'htmlSafeWildcardDomainExternalImageNotRemoved',
        message => _replaceInlineImageWithExternalImage(
            $htmlWithTextMessageWithInlineImage),
        content => {
            type       => 'html',
            processors => [
                {
                    pkg =>
'Foswiki::Contrib::MailInContrib::FilterExternalResources',
                    safedomains => '*.example.com'
                }
            ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => { text => $expectedContent{inlineImageMadeExternalHtml} },
    },
    {
        name    => 'htmlUnsafeDomainExternalImageRemoved1',
        message => _replaceInlineImageWithExternalImage(
            $htmlWithTextMessageWithInlineImage),
        content => {
            type       => 'html',
            processors => [
                {
                    pkg =>
'Foswiki::Contrib::MailInContrib::FilterExternalResources',
                    safedomains => 'other.org'
                }
            ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => { text => $expectedContent{inlineImageRemovedHtml} },
    },
    {
        name    => 'htmlUnsafeDomainExternalImageRemoved2',
        message => _replaceInlineImageWithExternalImage(
            $htmlWithTextMessageWithInlineImage),
        content => {
            type       => 'html',
            processors => [
                {
                    pkg =>
'Foswiki::Contrib::MailInContrib::FilterExternalResources',
                    safedomains => 'other.example.com'
                }
            ]
        },
        subject => '$this->{test_web}.AnotherTopic: HTML with inline image',
        match   => { text => $expectedContent{inlineImageRemovedHtml} },
    },
    {
        name    => 'plainTextNotAffectedByHtmlProcessors',
        message => $plainTextMessageContainingHtml,
        content => {
            type       => 'text',
            processors => [
                {
                    pkg =>
                      'Foswiki::Contrib::MailInContrib::FilterExternalResources'
                },
                { pkg => 'Foswiki::Contrib::MailInContrib::NoInlineContent' },
                { pkg => 'Foswiki::Contrib::MailInContrib::NoScript' },
            ]
        },
        subject => '$this->{test_web}.AnotherTopic: Html As Plain Text',
        match   => { text => $expectedContent{htmlAsPlainText} },
    },
);

sub _replaceInlineImageWithExternalImage {
    my $x = shift;
    $x =~ s{"cid:[^"]*"}{"http://www.example.com/turkey.png"};
    return $x;
}

sub doOneMimeMessage {
    my $this  = shift;
    my $datum = shift;

    my $mail = $datum->{message};
    $mail =~ s/\$this->{test_web}/$this->{test_web}/g;
    $this->sendTestMail($mail);

    $this->{MIC_box}->{topicPath} = 'subject';
    $this->{MIC_box}->{content}   = $datum->{content};
    my $c = $this->cron();
    $this->assert_null( $c->{error} );

    my ( $m, $t ) =
      Foswiki::Func::readTopic( $this->{test_web}, 'AnotherTopic' );

    # Check content
    my $subject = $datum->{subject};
    $subject =~ s/\$this->{test_web}/$this->{test_web}/g;
    $this->assert( 0, $t ) unless $t =~ s/^\s*\*\s*\*$subject\*: //s;
    my $expected = $datum->{match}->{text};
    $expected = $datum->{processText}->( $this, $expected )
      if $datum->{processText};
    $this->assert( 0, "'$t' !~ '$expected'" )
      unless $t =~ s/^\Q$expected\E\s*//s;
    $this->assert( 0, $t )
      unless $t =~
s/^_$this->{users_web}\.AllyGator\s*\@\s*\d+\s+\w+\s+\d+\s+-\s+\d+:\d+_//s;
    $this->assert_matches( qr/^\s*$/, $t );

    # Check that attachments are present
    my %expectedAttachments;
    %expectedAttachments = %{ $datum->{match}->{attach} }
      if $datum->{match}->{attach};
    my @a = $m->find('FILEATTACHMENT');
    $this->assert_equals( scalar( keys %expectedAttachments ), scalar(@a) );
    for my $attachment (@a) {
        $this->assert( $attachment->{attachment} );
        exists( $expectedAttachments{ $attachment->{attachment} } )
          or $this->assert( 0,
            "Unexpected attachment: '$attachment->{attachment}'" );
        my $expectedContentKey =
          delete $expectedAttachments{ $attachment->{attachment} };
        my $expectedValue = $expectedContent{$expectedContentKey};

        my $attachmentFilename =
"$Foswiki::cfg{PubDir}/$this->{test_web}/AnotherTopic/$attachment->{attachment}";
        open my $fh, "<", $attachmentFilename
          or $this->assert( 0,
            "Could not open attachment '$attachmentFilename': $!" );
        local $/;    # enable slurp mode
        my $actualValue = <$fh>;
        $this->assert_str_equals( $expectedValue, $actualValue );
    }

    for my $attachment ( keys %expectedAttachments ) {
        $this->assert( 0, "Missing attachment: '$attachment'" );
    }

    $this->assert_equals( 0, scalar( @{ $this->{MIC_mails} } ) );
}

sub gen_tests {
    my %picked = map { $_ => 1 } @_;
    for ( my $i = 0 ; $i < scalar(@tests) ; $i++ ) {
        my $datum = $tests[$i];
        if ( scalar(@_) ) {
            next unless ( $picked{ $datum->{name} } );
        }
        my $fn = 'MailInContribMimeTests::test_' . $datum->{name};
        no strict 'refs';
        *$fn = sub { my $this = shift; $this->doOneMimeMessage($datum) };
        use strict 'refs';
    }
}

gen_tests();

1;

