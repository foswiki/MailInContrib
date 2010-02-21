#---+ Extensions
#---++ MailInContrib
# **PERL**
# The configuration is in the form of an (perl) array of mailbox
# specifications. Each specification defines a number of fields:
# <ul>
#  <li> onError - what you want Foswiki to do if an error occurs while processing
#   a mail (comma-separated list of options). Available options:
#   <ul>
#    <li> reply - reply to the sender</li>
#    <li> delete - delete the mail from the inbox</li>
#    <li> log - log the error to the Foswiki warning log</li>
#   </ul>
#   Note: if you don't specify delete, Foswiki will continue to try to process the
#   mail each time the cron job runs.
#  </li>
#  <li> topicPath - where you want Foswiki to look for the name of the target
#   topic (comma-separated list of options). Available options:
#   <ul>
#    <li> to - look in the To: e.g. <code>Web.TopicName@example.com</code> or
#     <code>"Web TopicName" &lt;web.topicname@example.com&gt;</code> </li>
#    <li> subject - look in the Subject: e.g "Web.TopicName: mail for Foswiki"
#     If "to" and "subject" are both enabled, but a valid topic name is not
#     found in the To:, the Subject: will still be parsed to try and get the
#     topic.</li>
#   </ul></li>
#  <li> removeTopicFromSubject - if "true", remove the topic name from the subject
#      (only useful if the <code>topicPath</code> contains "subject").</li>
#  <li> folder - name of the mail folder<br />
#      Note: support for POP3 requires that the Email::Folder::POP3
#      module is installed. Support for IMAP requires
#      Email::Folder::IMAP etc.
#      Folder names are as described in the documentation for the
#      relevant Email::Folder type e.g. for POP3, the folder name might be:
#      <code>pop://me:123@mail.isp.com:110/</code></li>
#  <li> user - name of the default user.<br />
#      The From: in the mail is parsed to extract the senders email
#      address. This is then be looked up in the users database
#      to find the wikiname. If the user is not found, then this default
#      user will be used. If the default user is left blank, then the
#      user *must* be found from the mail.
#      The identity of the sending user is important for access controls.
#      This must be a user *login* name.e.g. 'guest'
#  </li>
#  <li> onSuccess - what  you want Foswiki to do with messages that have been successfully added to a Foswiki topic
#     (comma-separated list of options)
#     Available options:
#   <ul>
#    <li> reply - reply to the sender</li>
#    <li> delete - delete the mail from the inbox</li>
#   </ul>
#  <li> defaultWeb - name of the web to save mails in if the web name isn't
#   specified in the mail. If this is undefined or left blank, then mails must
#   contain a full web.topicname or the mail will be rejected.</li>
#  <li> onNoTopic - what do you want Foswiki to do if it can't find a valid
#   topic name in the mail (one option). Available options:
#   <ul>
#    <li> error - treat this as an error (overrides all other options)</li>
#    <li> spam - save the mail in the spambox topic.
#    Note: if you clear this, then Foswiki will simply ignore the mail.</li>
#   </ul>
#  </li>
#  <li> spambox - optional, required if onNoTopic = spam. Name of the topic
#   where you want to save mails that don't have a valid web.topic. You must
#   specify a full web.topicname
#  </li>
#  <li> ignoreMessageTime - optional. If "false" (which is the default),
#   then the MailInContrib ignores previously-processed mail, as determined
#   by the mail "Date". If "true", then MailInContrib does not filter mail
#   based on the "Date" - which may be important if the interval between
#   <code>mailincron</code> runs is less than the message propagation time
#   or less than the error in the sending PC's clock. 
#   <em>It is <strong>only</strong> useful to set <code>ignoreMessageTime
#   </code> to 1 if both <code>onError</code> and <code>onSuccess</code>
#   contain "delete".</em> Otherwise, <em>every</em> message will processed 
#   <em>every time</em> that <code>mailincron</code> runs.
#  </li>
#  <li> content - optional, defaults to "extract plain text". 
#   Specifies what part of the mail to extract and how to process it.
#   It takes a number of fields:
#   <ul>
#    <li> type - specifies type of content to extract. 
#       Available options:
#     <ul>
#      <li> text - extract the plain-text portion </li>
#      <li> html - extract the HTML portion, by preference 
#        - reverts to the plain-text if the mail does not contain HTML 
#      </li>
#      <li> debug - extract the whole MIME message, verbatim </li>
#     </ul>
#    </li>
#    <li> processors - specifies a list of processors, to be applied in the order listed.
#       Each processor is described by a perl Hash. The <em>pkg</em> key identifies the
#       Perl package that provides the processor. Any other keys are passed as options
#       to the processor. </li>
#   </ul>
#  </li>
# </ul>
$Foswiki::cfg{MailInContrib} = [
 {
   folder => 'pop://example_user:password@example.com/Inbox',
   onError => 'log',
   onNoTopic => 'error',
   onSuccess => 'log delete',
   topicPath => 'to subject',
   removeTopicFromSubject => 1,
   ignoreMessageTime => 0,
   processors => [
        { pkg => 'Foswiki::Contrib::MailInContrib::NoScript' },
        { pkg => 'Foswiki::Contrib::MailInContrib::FilterExternalResources' },
   ],
 },
];

1;
