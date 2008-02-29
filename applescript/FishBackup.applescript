set the appName to "FishBackup"
tell application "GrowlHelperApp"
	set the allNotificationsList to {"start", "end"}
	set the enabledNotificationsList to {"start", "end"}
	
	register as application �
		appName all notifications allNotificationsList �
		default notifications enabledNotificationsList �
		icon of application "Script Editor"
	
	notify with name �
		"start" title �
		"Starting" description �
		"Starting backup of FISH" application name appName
end tell

do shell script "rsync -rat --delete /Volumes/FISH/ /Users/dustin/bak/FISH/"

tell application "GrowlHelperApp"
	notify with name �
		"end" title �
		"Completed" description �
		"Completed backup of FISH" application name appName
	
end tell