#
# Copyright (C) 2014  stfn <stfnmd@gmail.com>
# https://github.com/stfnm/weechat-scripts
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
	name => 'spin-notify',
	author => 'stfn <stfnmd@gmail.com>',
	version => '0.1',
	license => 'GPL3',
	desc => 'Notifications for spin plugin',
	opt => 'plugins.var.perl',
);
my %OPTIONS_DEFAULT = (
	'enabled' => ['on', "Turn script on or off"],
	'service' => ['pushover', 'Notification service to use (supported services: pushover, nma)'],
	'pushover_token' => ['', 'pushover API token/key'],
	'pushover_user' => ['', "pushover user key"],
	'nma_apikey' => ['', "nma API key"],
	'priority' => ['', "priority (empty for default)"],
	'only_if_away' => ['off', 'Notify only if away status is active'],
);
my %OPTIONS = ();
my $TIMEOUT = 20 * 1000;
my $DEBUG = 0;

# Register script and setup hooks
weechat::register($SCRIPT{"name"}, $SCRIPT{"author"}, $SCRIPT{"version"}, $SCRIPT{"license"}, $SCRIPT{"desc"}, "", "");
weechat::hook_signal("spin_friend_login", "spin_signal", "");
weechat::hook_signal("spin_friend_logout", "spin_signal", "");
weechat::hook_signal("spin_new_mail", "spin_signal", "");
weechat::hook_signal("spin_new_gift", "spin_signal", "");
weechat::hook_signal("spin_new_gb", "spin_signal", "");
weechat::hook_signal("spin_new_comment", "spin_signal", "");
weechat::hook_hsignal("spin_private_msg", "spin_hsignal", "");
weechat::hook_hsignal("spin_channel_msg", "spin_hsignal", "");
init_config();

#
# Handle config stuff
#
sub init_config
{
	weechat::hook_config("$SCRIPT{'opt'}.$SCRIPT{'name'}.*", "config_cb", "");
	my $version = weechat::info_get("version_number", "") || 0;
	foreach my $option (keys %OPTIONS_DEFAULT) {
		if (!weechat::config_is_set_plugin($option)) {
			weechat::config_set_plugin($option, $OPTIONS_DEFAULT{$option}[0]);
			$OPTIONS{$option} = $OPTIONS_DEFAULT{$option}[0];
		} else {
			$OPTIONS{$option} = weechat::config_get_plugin($option);
		}
		if ($version >= 0x00030500) {
			weechat::config_set_desc_plugin($option, $OPTIONS_DEFAULT{$option}[1]." (default: \"".$OPTIONS_DEFAULT{$option}[0]."\")");
		}
	}
}
sub config_cb
{
	my ($pointer, $name, $value) = @_;
	$name = substr($name, length("$SCRIPT{opt}.$SCRIPT{name}."), length($name));
	$OPTIONS{$name} = $value;
	return weechat::WEECHAT_RC_OK;
}

#
# Signal hooks
#
sub spin_signal
{
	my ($data, $signal, $signal_data) = @_;
	my $user = $signal_data;

	if ($signal eq "spin_new_mail") {
		notify("$user mailed you.");
	} elsif ($signal eq "spin_new_gift") {
		notify("$user sent you a gift.");
	} elsif ($signal eq "spin_new_gb") {
		notify("$user left you a new GB entry.");
	} elsif ($signal eq "spin_new_comment") {
		notify("$user left you a new comment.");
	}
}

sub spin_hsignal
{
	my ($data, $signal, $hashtable) = @_;
	my %hash = %{$hashtable};

	if ($signal eq "spin_private_msg" && $hash{type} ne "0" && $hash{echo} eq "0") {
		notify("$hash{user}: $hash{msg}");
	} elsif ($signal eq "spin_channel_msg" && $hash{type} ne "0" && $hash{highlight} eq "1") {
		notify("[$hash{channel}] $hash{user}: $hash{msg}");
	}
}

#
# Notify wrapper (decides which service to use)
#
sub notify($)
{
	my $msg = $_[0];
	my $message = "[spin] $msg";
	my $away = (weechat::info_get("spin_is_away", "") eq "1") ? 1 : 0;

	# Script disabled for any reason?
	if ($OPTIONS{enabled} ne "on" || ($OPTIONS{only_if_away} eq "on" && $away == 0)) {
		return weechat::WEECHAT_RC_OK;
	}

	# Notify service
	if ($OPTIONS{service} eq "pushover") {
		notify_pushover($OPTIONS{pushover_token}, $OPTIONS{pushover_user}, $message, "weechat", $OPTIONS{priority}, "");
	} elsif ($OPTIONS{service} eq "nma") {
		notify_nma($OPTIONS{nma_apikey}, "weechat", "notification", $message, $OPTIONS{priority});
	}
}

#
# https://pushover.net/api
#
sub notify_pushover($$$$$$)
{
	my ($token, $user, $message, $title, $priority, $sound) = @_;

	# Required API arguments
	my @post = (
		"token=" . CGI::escape($token),
		"user=" . CGI::escape($user),
		"message=" . CGI::escape($message),
	);

	# Optional API arguments
	push(@post, "title=" . CGI::escape($title)) if ($title && length($title) > 0);
	push(@post, "priority=" . CGI::escape($priority)) if ($priority && length($priority) > 0);
	push(@post, "sound=" . CGI::escape($sound)) if ($sound && length($sound) > 0);

	# Send HTTP POST
	my $hash = { "post"  => 1, "postfields" => join(";", @post) };
	if ($DEBUG) {
		weechat::print("", "[$SCRIPT{name}] Debug: msg -> `$message' HTTP POST -> @post");
	} else {
		weechat::hook_process_hashtable("url:https://api.pushover.net/1/messages.json", $hash, $TIMEOUT, "", "");
	}

	return weechat::WEECHAT_RC_OK;
}

#
# http://www.notifymyandroid.com/api.jsp
#
sub notify_nma($$$$$)
{
	my ($apikey, $application, $event, $description, $priority) = @_;

	# Required API arguments
	my @post = (
		"apikey=" . CGI::escape($apikey),
		"application=" . CGI::escape($application),
		"event=" . CGI::escape($event),
		"description=" . CGI::escape($description),
	);

	# Optional API arguments
	push(@post, "priority=" . CGI::escape($priority)) if ($priority && length($priority) > 0);

	# Send HTTP POST
	my $hash = { "post"  => 1, "postfields" => join("&", @post) };
	if ($DEBUG) {
		weechat::print("", "[$SCRIPT{name}] Debug: msg -> `$description' HTTP POST -> @post");
	} else {
		weechat::hook_process_hashtable("url:https://www.notifymyandroid.com/publicapi/notify", $hash, $TIMEOUT, "", "");
	}

	return weechat::WEECHAT_RC_OK;
}
