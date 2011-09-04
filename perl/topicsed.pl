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

#
# Development is currently hosted at
# https://github.com/stfnm/weechat-scripts
#

use strict;
use warnings;

my %SCRIPT = (
	name => 'topicsed',
	author => 'stfn <stfnmd@googlemail.com>',
	version => '0.1',
	license => 'GPL3',
	desc => 'Edit channel topics by perl regular expressions',
);

weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");
weechat::hook_command($SCRIPT{"name"}, $SCRIPT{"desc"}, "<regex>", "", "%(irc_channel_topic)", "command_cb", "");

sub command_cb
{
	my ($data, $buffer, $args) = @_;
	
	my $topic = weechat::buffer_get_string($buffer, "title");
	my $x = $topic;
	my $preview = 0;
	my $regex = $args;

	if ($regex =~ /^-p(review|) ?/) {
		$preview = 1;
		$regex =~ s/^-p\w* ?//;
	}

	unless (eval "\$x =~ $regex") {
		weechat::print($buffer, weechat::prefix("error") . "topicsed: An error occurred with your regex.");
		return weechat::WEECHAT_RC_OK;
	}

	if ($x eq $topic) {
		weechat::print($buffer, weechat::prefix("error") . "topicsed: The topic wouldn't be changed.");
		return weechat::WEECHAT_RC_OK;
	} elsif ($x eq "") {
		weechat::print($buffer, weechat::prefix("error") . "topicsed: Edited topic is empty; try '/topic -delete' instead.");
		return weechat::WEECHAT_RC_OK;
	}

	if ($preview) {
		weechat::print($buffer, "topicsed: Edited topic preview: $x");
	} else {
		weechat::command($buffer, "/topic $x");
	}

	return weechat::WEECHAT_RC_OK;
}
