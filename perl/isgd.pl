#
# Copyright (C) 2011  stfn <stfnmd@googlemail.com>
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

#
# Development is currently hosted at
# https://github.com/stfnm/weechat-scripts
#

use strict;
use warnings;
use CGI;

my %SCRIPT = (
	name => 'isgd',
	author => 'stfn <stfnmd@googlemail.com>',
	version => '0.2',
	license => 'GPL3',
	desc => 'Shorten URLs with is.gd on command',
);
my $TIMEOUT = 30 * 1000;

weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");
weechat::hook_command($SCRIPT{"name"}, "Shorten last found URL in current buffer", "", "", "", "command_cb", "");

sub command_cb
{
	my ($data, $buffer, $args) = @_;
	my $infolist = weechat::infolist_get("buffer_lines", $buffer, "");

	while (weechat::infolist_prev($infolist) == 1) {
		my $message = weechat::infolist_string($infolist, "message");
		my $url = "";
		while ($message =~ m{(https?://\S+)}gi) {
			$url = $1;
			unless ($url =~ m{^https?://is\.gd/}gi) {
				my $escaped = CGI::escape($url);
				weechat::hook_process("wget -qO - \"http://is.gd/create.php?format=simple&url=$escaped\"", $TIMEOUT, "process_cb", $buffer);
			}
		}
		last if ($url);
	}
	weechat::infolist_free($infolist);

	return weechat::WEECHAT_RC_OK;
}

sub process_cb
{
	my ($data, $command, $return_code, $out, $err) = @_;
	my $buffer = $data;

	if ($return_code == 0 && $out) {
		weechat::print($buffer, weechat::color("darkgray") . $out);
	}

	return weechat::WEECHAT_RC_OK;
}
