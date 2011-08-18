#
# Copyright (C) 2011 by stfn <stfnmd@googlemail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use CGI;

my %SCRIPT = (
	name => 'isgd',
	author => 'stfn <stfnmd@googlemail.com',
	version => '1.0',
	license => 'GPL3',
	desc => 'Simply shorten incoming URLs with is.gd',
);
my $TIMEOUT = 30 * 1000;

weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");
weechat::hook_print("", "", "", 1, "print_cb", "");

sub print_cb
{
	my ($data, $buffer, $date, $tags, $displayed, $highlight, $prefix, $message) = @_;
	
	while ($message =~ m{(https?://\S+)}ig) {
		my $url = $1;	
		unless ($url =~ m{^https?://is\.gd/}ig) {
			my $escaped = CGI::escape($url);
			weechat::hook_process("wget -qO - \"http://is.gd/create.php?format=simple&url=$escaped\"", $TIMEOUT, "process_cb", $buffer);
		}
	}

	return weechat::WEECHAT_RC_OK;
}

sub process_cb
{
	my ($data, $command, $return_code, $out, $err) = @_;
	my $buffer = $data;
	
	if ($return_code >= 0 && $out) {
		weechat::print($buffer, weechat::color("darkgray") . $out);
	}

	return weechat::WEECHAT_RC_OK;
}
