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
	name => 'goto',
	author => 'stfn <stfnmd@googlemail.com>',
	version => '1.0',
	license => 'GPL3',
	desc => 'Implements /go command to switch to a buffer in current window',
);

weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");
weechat::hook_command("go", "Go to buffer", "[name]", "", "%(buffers_names)", "command_cb", "");

sub command_cb
{
	my ($data, $buffer, $args) = @_;

	my $infolist = weechat::infolist_get("buffer", "", "");
	my $chan = $args;
	$chan =~ s/ *//g;

	while (weechat::infolist_next($infolist)) {
		my $name = weechat::infolist_string($infolist, "name");
		my $pointer = weechat::infolist_pointer($infolist, "pointer");

		if ($name =~ /^#?\Q${chan}\E/i) {
			weechat::buffer_set($pointer, "display", "1");
			last;
		}
	}

	weechat::infolist_free($infolist);

	return weechat::WEECHAT_RC_OK;
}
