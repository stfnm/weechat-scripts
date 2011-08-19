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

my %SCRIPT = (
	name => 'ncmpcpp',
	author => 'stfn <stfnmd@googlemail.com>',
	version => '1.0',
	license => 'GPL3',
	desc => 'Display now playing information with ncmpcpp',
);
my $TIMEOUT = 30 * 1000;

weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");
weechat::hook_command("np", "Send ncmpcpp's now-playing info", "", "", "", "command_cb", "");

sub command_cb
{
	my ($data, $buffer, $args) = @_;
	weechat::hook_process("ncmpcpp --now-playing '%a \"%b\" (%y) - %t'", $TIMEOUT, "process_cb", $buffer);

	return weechat::WEECHAT_RC_OK;
}

sub process_cb
{
	my ($data, $command, $return_code, $out, $err) = @_;

	if ($return_code >= 0 && $out) {
		chomp($out);
		weechat::command($data, "/me np: $out");
	}

	return weechat::WEECHAT_RC_OK;
}
