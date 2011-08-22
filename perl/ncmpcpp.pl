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
	version => '0.1',
	license => 'GPL3',
	desc => 'Control and "now playing" script for ncmpcpp',
);
my $TIMEOUT = 30 * 1000;
my $COMMANDS = "play|pause|toggle|stop|next|prev";

weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");
weechat::hook_command("np", "Control ncmpcpp", "[$COMMANDS]", "without any arguments, \"now playing\" info is sent", $COMMANDS, "command_cb", "");

sub command_cb
{
	my ($data, $buffer, $args) = @_;

	my $cmd;
	$cmd = "play" if ($args =~ /^play$/i);
	$cmd = "pause" if ($args =~ /^pause$/i);
	$cmd = "toggle" if ($args =~ /^toggle$/i);
	$cmd = "stop" if ($args =~ /^stop$/i);
	$cmd = "next" if ($args =~ /^next$/i);
	$cmd = "prev" if ($args =~ /^prev$/i);
	$cmd = "--now-playing '%a \"%b\" (%y) - %t'" if ($args =~ /^\s*$/);

	weechat::hook_process("ncmpcpp $cmd", $TIMEOUT, "process_cb", $buffer);

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
