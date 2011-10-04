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
use POSIX qw(strftime);

my %SCRIPT = (
	name => 'rawlogger',
	author => 'stfn <stfnmd@googlemail.com>',
	version => '0.1',
	license => 'GPL3',
	desc => 'Log raw IRC messages from/to server',
);
my $PREFIX = '%Y-%m-%d %H:%M:%S';
my $FILE_MASK = '%Y-%m-%d_$server.log';
my $FILE_PATH = '$home/rawlogs/%Y/%b-%Y/';

weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");

# Setup hooks to catch in and out going raw messages
weechat::hook_signal("*,irc_raw_in_*", "raw_msg_cb", "");
weechat::hook_signal("*,irc_out_*", "raw_msg_cb", "");

sub raw_msg_cb
{
	my ($data, $signal, $signal_data) = @_;
	my $server = "";
	$server = $1 if ($signal =~ /^(.*),/);
	write_log($server, $signal_data);

	return weechat::WEECHAT_RC_OK;
}

sub write_log
{
	my ($server, $data) = @_;
	my $path = compile_mask($FILE_PATH, $server);
	my $file = compile_mask($FILE_MASK, $server);
	my $prefix = compile_mask($PREFIX, $server);

	# Create directory tree unless path exists already on file system
	weechat::mkdir_parents($path, 0755) unless (-d $path);

	# Append to file
	if (open(FILE, ">>", $path . $file)) {
		print FILE "$prefix $data\n";
		close(FILE);
	}
}

sub compile_mask
{
	my ($path, $server) = @_;
	my $home = weechat::info_get("weechat_dir", "");

	# Substitute all variables
	$path = strftime($path, localtime());
	$path =~ s/\$home/$home/gi;
	$path =~ s/\$server/$server/gi;

	return $path;
}
