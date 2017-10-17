-- HTC sous-dev
-- 2017-05-03, Erik Shagdar, NYHTC

-- written against OS X 10.10.5 and FileMaker 15.0.3


property AppletName : "HTC sous-dev"

property debugMode : false
property logging : true

property orgNumLIST : {1, 2}

property idleTime : 5 * minutes

property credentialsTimeout : 2 * hours
property credentialsUpdatedTS : (current date) - credentialsTimeout
property fullAccessCredentials : {}
property userCredentials : {}



use htcBasic : script "htcBasic"
use credentialsLib : script "credentials"
use privSetLib : script "privSet"
use scripting additions



on run
	try
		if logging then htcBasic's logToConsole("Here I am")
		mainScript({})
	on error errMsg number errNum
		tell it to activate
		display dialog errMsg & ", errNum: " & errNum
	end try
	
end run


on reopen
	mainScript({})
end reopen


on idle
	credentialsCheck({})
	return idleTime
end idle


on quit
	credentialsCheck({forceClear:true})
	
	continue quit
end quit



on mainScript(prefs)
	try
		-- set properties in script libraries
		--set AppletName of privSetLib to my AppletName
		
		
		launchHtcLib({})
		
		if not debugMode then credentialsEnsure({})
		runProcess({})
		
	on error errMsg number errNum
		tell it to activate
		tell application "htcLib" to set errStack to replaceSimple({sourceTEXT:errMsg, oldChars:" - ", newChars:return})
		set ignoreErrorNumList to {-128, -1024, -1719}
		(*
			-128: user cancel
			-1024: generic error
			-1719: assistive device
		*)
		if errNum is not in ignoreErrorNumList then set errStack to errStack & " ( errNum: " & errNum & " )"
		htcBasic's showUserError(errStack)
	end try
end mainScript



on launchHtcLib(prefs)
	-- attempt to open htcLib. if it doesn't exist, navigate user to github
	
	-- 2017-06-28 ( eshagdar ): create
	
	set openName to "Get it!"
	set repoURL to "https://github.com/NYHTC/applescript-fm-helper"
	
	try
		if logging then htcBasic's logToConsole("launching htcLib")
		tell application "htcLib" to launch
	on error errMsg number errNum
		set missingAppDialog to display dialog "You do Not have the htcLib installed." with title AppletName buttons {"Cancel", openName} default button openName
		if button returned of missingAppDialog is openName then open location repoURL
		error "unable to launchHtcLib - " & errMsg number errNum
	end try
end launchHtcLib



on promptProcess(prefs)
	-- user user for which process to do
	
	-- 2017-06-28 ( eshagdar ): created
	
	set defaultPrefs to {processList:{}}
	set prefs to prefs & defaultPrefs
	
	try
		if logging then htcBasic's logToConsole("About to ask user to process")
		set promptProcessDialog to (choose from list processList of prefs with title AppletName with prompt "Select a process" OK button name "Run" without multiple selections allowed and empty selection allowed)
		if promptProcessDialog is false then return promptProcessDialog
		set processName to item 1 of promptProcessDialog
		if logging then htcBasic's logToConsole("Process: " & processName)
		return processName
		
	on error errMsg number errNum
		error "unable to promptProcess - " & errMsg number errNum
	end try
end promptProcess



on runProcess(prefs)
	-- run process specified by the user
	
	-- 2017-06-28 ( eshagdar ): created.
	
	try
		set processList to {Â
			"DO NOTHING", Â
			"Full Access Toggle", Â
			"Db Manage", Â
			"Security Open", Â
			"Security Save", Â
			"PrivSet - copy settings to other PrivSets", Â
			"New table", Â
			"Data Viewer", Â
			"Clipboard Clear", Â
			"Credentials Update"}
		
		set oneProcess to promptProcess({processList:processList})
		if oneProcess is equal to "DO NOTHING" or oneProcess is equal to false then
			return true
			
			
		else if oneProcess is equal to "Full Access Toggle" then
			return fullAccessToggle({})
			
			
		else if oneProcess is equal to "Db Manage" then
			display dialog "This process is not yet finished" with title AppletName buttons "OK" default button "OK"
			return true
			
			
		else if oneProcess is equal to "Security Open" then
			tell application "htcLib"
				fmGUI_AppFrontMost()
				return fmGUI_ManageSecurity_GoToTab_PrivSets(fullAccessCredentials)
			end tell
			
			
		else if oneProcess is equal to "Security Save" then
			tell application "htcLib"
				fmGUI_AppFrontMost()
				return fmGUI_ManageSecurity_Save(fullAccessCredentials)
			end tell
			
			
		else if oneProcess is equal to "PrivSet - copy settings to other PrivSets" then
			return privSetLib's copyPrivSetToOthers({})
			
			
		else if oneProcess is equal to "New table" then
			display dialog "This process is not yet finished" with title AppletName buttons "OK" default button "OK"
			return true
			
			
		else if oneProcess is equal to "Data Viewer" then
			display dialog "This process is not yet finished" with title AppletName buttons "OK" default button "OK"
			return true
			
			
		else if oneProcess is equal to "Clipboard Clear" then
			set the clipboard to null
			return true
			
			
		else if oneProcess is equal to "Credentials Update" then
			return credentialsLib's credentialsUpdate(fullAccessCredentials & userCredentials)
			
			
		else
			return false
		end if
		
	on error errMsg number errNum
		error "unable to runProcess - " & errMsg number errNum
	end try
end runProcess



-- ########## ########## ##########
-- ##########   credentials   ##########
-- ########## ########## ##########




on credentialsCheck(prefs)
	-- clear credentials if past the timeout
	
	-- 2017-10-10 ( eshagdar ): added forceClear option.
	-- 2017-05-03 ( eshagdar ): first created.
	
	try
		set defaultPrefs to {forceClear:false}
		set prefs to prefs & defaultPrefs
		
		set resetTime to (current date) - credentialsTimeout
		
		if forceClear of prefs then
			set fullAccessCredentials to {}
			set userCredentials to {}
			set credentialsUpdatedTS to resetTime
			(*
			htcBasic's debugMsg("001 - " & Â
				"fullAccessCredentials: " & htcBasic's coerceToString(fullAccessCredentials) & return & Â
				"userCredentials: " & htcBasic's coerceToString(userCredentials) & return & Â
				"fullAccessCredentials of privSetLib: " & htcBasic's coerceToString(fullAccessCredentials of privSetLib))
			*)
			
		else if resetTime > credentialsUpdatedTS then
			try
				set fullAccessCredentials to {fullAccessAccountName:fullAccessAccountName of fullAccessCredentials}
				set userCredentials to {userAccountName:userAccountName of userCredentials}
			on error
				set fullAccessCredentials to {}
				set userCredentials to {}
			end try
			set credentialsUpdatedTS to resetTime
			
		end if
		
		return true
	on error errMsg number errNum
		error "unable to credentialsCheck - " & errMsg number errNum
	end try
end credentialsCheck



on credentialsEnsure(prefs)
	-- ensure credentials are set
	
	-- 2017-05-03 ( eshagdar ): first created.
	
	try
		credentialsCheck({})
		
		try
			set credentialsList to {fullAccessCredentials, userCredentials}
			repeat with i from 1 to count of credentialsList
				set oneCredential to item i of credentialsList
				if length of oneCredential is 0 or oneCredential is "" then error "empty credentail [ " & i & " ]"
			end repeat
		on error errMsg number errNum
			credentialsLib's credentialsUpdate(fullAccessCredentials & userCredentials)
		end try
		
		return true
	on error errMsg number errNum
		error "unable to credentialsEnsure - " & errMsg number errNum
	end try
	return false
end credentialsEnsure



on fullAccessToggle(prefs)
	-- toggle between full-access and regular user level
	
	-- 2017-10-06 ( eshagdar ): created
	
	try
		tell application "htcLib" to set isAlreadyInFullAccess to fmGUI_isInFullAccessMode({})
		if logging then htcBasic's logToConsole("START: full access toggle")
		
		if isAlreadyInFullAccess then
			-- LEAVE full access
			
			if logging then htcBasic's logToConsole("DONE: already full, so LEAVE")
			tell application "System Events"
				tell process "FileMaker Pro"
					set windowNames to name of every window
				end tell
			end tell
			
			if windowNames contains "Full Access" then
				tell application "FileMaker Pro Advanced"
					do script (first FileMaker script whose name contains "Full Access Switch OFF")
				end tell
				tell application "htcLib" to fmGUI_relogin({accountName:userAccountName of userCredentials, pwd:userPassword of userCredentials})
			end if
			
		else
			-- enter full access
			
			if logging then htcBasic's logToConsole("DONE: enter full")
			tell application "FileMaker Pro Advanced"
				do script (first FileMaker script whose name contains "Full Access Switch ON")
			end tell
			tell application "htcLib" to fmGUI_relogin({accountName:fullAccessAccountName of fullAccessCredentials, pwd:fullAccessPassword of fullAccessCredentials})
			
		end if
		
		if logging then htcBasic's logToConsole("DONE: full access toggle")
		
		return true
	on error errMsg number errNum
		error "unable to fullAccessToggle - " & errMsg number errNum
	end try
end fullAccessToggle


