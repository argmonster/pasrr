#web page content change alert for pages requiring basic auth
#This script will grab a web page from url, check the md5 hash against a locally stored copy of the page
#If the hashes do not match send an email notification with the new web content and replace the local copy
#
# Tim Markello
# with special thanks to Robert Edeker
#
# Version 0.2 6/28/2013
#
#RLE 20130628 .1
#  + file archiving
#  + use of $FindBin to locate running directory
#
#Tim 20130628 .2
#  + auto file creation for $cur
#
# To do:
#  error handling for missconfiguration
#  maybe option to turn off archive files?
#  maybe option to turn off basic authentication

use HTTP::Request;
use LWP::UserAgent;
use Digest::MD5;
use Net::SMTP;
use Time::Piece;
use File::Copy;
use FindBin;

#script settings -- please set these variable for the script to work correctly
my $user = 'yourTMHPuserid';
my $pass = 'yourTMHPpassword';
my $emailaddr = 'notify@email.com';
my $mailhost = 'mail.host.server';

#should have to change these
my $new = "$FindBin::Bin/tmhp-new";
my $cur = "$FindBin::Bin/tmhp-cur";
my $archivePath = "$FindBin::Bin/archive";

#this is the tmhp alert page url - edit this if TMHP moves the alert page
my $url = 'https://secure.tmhp.com/Careforms/Default.aspx?pn=Controls%2fShared%2fAlerts';

#make sure we have the files we need
if (! -e $cur) {
   open(file, ">$cur");
}
#archive dir
if (! -e $archivePath) {
   mkdir($archivePath);
}

#timestamp for archive YYYY-MM-DD_HHMMSS
my $dt_str = localtime->strftime('%Y-%m-%d_%H%M%S');

#get the webpage
my $ua = LWP::UserAgent->new(ssl_opts => {verify_hostname => 0});
my $req = HTTP::Request->new(GET => $url);
$req->authorization_basic($user, $pass);
my $res = $ua->request($req);

#compare the new and current files
open(file, "> $new");
print file $res->decoded_content;
close(file);
my $md5_1 = getMD5($new);
my $md5_2 = getMD5($cur);

#email notification if the files do not match
if ($md5_1 ne $md5_2){
   print "*** new alert ****\n";
   copy($new,$cur);
   my $archiveFile = $archivePath . '/' . $dt_str . '.html';
   copy($new,$archiveFile);

   my $smtp = Net::SMTP->new($mailhost, Timeout => 60, Debug => 0);
   $smtp->mail($emailaddr);
   $smtp->to($emailaddr);
   $smtp->data();
   $smtp->datasend("From: $emailaddr\n");
   $smtp->datasend("To: $emailaddr\n");
   $smtp->datasend("Subject: PASRR Alert!\n");
   $smtp->datasend("Content-Type: text/html");
   $smtp->datasend("\n\n");
   $smtp->datasend($res->decoded_content);
   $smtp->dataend();
   $smtp->quit();
}
exit;

#md5 hash helper function
sub getMD5($) {
   my $file = shift;
   $ctx = Digest::MD5->new;
   open(my $fh, '<', $file) or die "Can't open '$filename': $!";
   binmode($fh);
   return $ctx->addfile($fh)->hexdigest;
}