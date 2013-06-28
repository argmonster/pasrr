#web page content change alert for pages requiring basic auth
#This script will grab a web page from url, check the md5 hash against a locally stored copy of the page
#If the hashes do not match send an email notification with the new web content and replace the local copy
#
# Tim Markello 
# with special thanks to Robert Edeker
#
# Version 0.0 6/25/2013
#
# To do: 
#  error handling for missconfiguration
#  maybe option to archive files instead of clobber?
#  maybe option to turn off basic authentication

use HTTP::Request;
use LWP::UserAgent;
use Digest::MD5;
use Net::SMTP;

#script settings -- please set these variable for the script to work
my $user = "TMarkello";
my $pass = "secrettmhppass";
my $url = "https://secure.tmhp.com/Careforms/Default.aspx?pn=Controls%2fShared%2fAlerts";
my $new = "./tmhp-new";
my $cur = "./tmhp-cur";
my $emailaddr = 'pasrr@gcmhmr.com';
my $mailhost = "mail.gcmhmr.com";

###my $emailaddr = 'app-notify@gcmhmr.com';

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
##print "$new -- $md5_1\n";
my $md5_2 = getMD5($cur);
##print "$cur -- $md5_2\n";

#email notification if the files do not match
if ($md5_1 ne $md5_2){
	print "*** new alert ****\n";
	open(file, "> $cur");
	print file $res->decoded_content;
	close(file);
	my $smtp = Net::SMTP->new($mailhost, Timeout => 60, Debug => 1);
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