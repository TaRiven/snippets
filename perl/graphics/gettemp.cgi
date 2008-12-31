#!/usr/local/bin/perl
# Copyright (c) 1998  Dustin Sallings
#
# $Id: gettemp.cgi,v 1.5 1999/12/09 08:59:53 dustin Exp $

use LWP::UserAgent;
use CGI;
use GD;
use strict;

sub getfile
{
    my($ua,$req,$res);
    $ua=LWP::UserAgent->new;
    $ua->agent('DustinPlayer/0.1' . $ua->agent);
    $req=HTTP::Request->new('GET', $_[0]);
    $res=$ua->request($req);
    return($res->content);
}

sub otherpoints
{
	my($temp)=@_;
	my($x, $y, $angle, $trans, $rad);

	if($temp>140) {
		$temp=140;
	} elsif($temp<-40) {
		$temp=-40;
	}

	$trans=-90;

	$angle=($temp*1.8)+$trans;
	$angle=$angle;
	$rad=( ($angle/360) * 2 * 3.14159265358979 );
	$x=sin($rad)*39;
	$y=cos($rad)*39;
	$y=-$y; # reverse the y because it's upside-down.
	return($x, $y);
}

my($temp, $q, $img, $x, $y, $black, %whence, $place);

%whence=(
	'machineroom' => 'http://keyhole/~dustin/temp/current/1013A51E00000035',
	'bedroom' => 'http://dhcp-104/~dustin/temp/current/1081841E000000DF',
);

if(@ARGV>0) {
	$place=$ARGV[0];
} else {
	$place='machineroom';
}

if(!defined($whence{$place})) {
	$place='machineroom';
}

$temp=getfile($whence{$place});
$temp+=0.0;

$q=CGI->new;

# print "Content-type: image/gif\nX-Temperature: $temp\n\n";
print $q->header(-type => 'image/gif', '-expires' => '+10m',
				'-X-temp' => $temp);

$temp=sprintf("%.02f", $temp);
open(GIF, "/usr/people/dustin/public_html/images/therm.gif");
$img=GD::Image->newFromGif(*GIF);
close(GIF);
$img->transparent($img->getPixel(0,0));

$black=$img->colorAllocate(0,0,0);

# $img->line(66,65, 105,65, $black);
# $img->line(66,65, 93,92, $black);
($x,$y)=otherpoints($temp);
$img->line(66,65, ($x+66), ($y+65), $black);
# Put the actual temperature all up in there.
$img->string(gdSmallFont, 52, 75, $temp, $black);

print $img->gif;
