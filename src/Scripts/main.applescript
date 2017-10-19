-- HTC sous-dev
-- 2017-05-03, Erik Shagdar, NYHTC

-- written against OS X 10.10.5 and FileMaker 15.0.3

(*
	2017-10-19 ( eshagdar ): open data viewer. open manage DB. 'added Functions Open' process
	2017-10-17 ( eshagdar ): update 'promptProcess' to show credential expiration TS.
	2017-10-16 ( eshagdar ): converted app to source files.
	2017-05-03 ( eshagdar ): created.
*)


property AppletName : "HTC sous-dev"

property debugMode : false
property logging : false

property orgNumLIST : {1, 2}

property idleTime : 5 * minutes

property credentialsTimeout : 2 * minutes --2 * hours
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
	credentialsLib's credentialsCheck({})
	return idleTime
end idle


on quit
	credentialsLib's credentialsCheck({forceClear:true})
	continue quit
end quit



on mainScript(prefs)
	try
		-- launch htcLib
		launchHtcLib({})
		
		
		-- credentials debugging
		if debugMode then htcBasic's debugMsg("mainScript ---" & return & Â
			"fullAccessCredentials: " & htcBasic's coerceToString(fullAccessCredentials) & return & Â
			"userCredentials: " & htcBasic's coerceToString(userCredentials))
		
		
		-- ensure credentials are not outdated
		credentialsLib's credentialsEnsure({})
		
		
		-- prompt user what to do
		return runProcess({})
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
	
	-- 2017-10-17 ( eshagdar ): add expiration TS to prompt.
	-- 2017-06-28 ( eshagdar ): created
	
	set defaultPrefs to {processList:{}}
	set prefs to prefs & defaultPrefs
	
	try
		if logging then htcBasic's logToConsole("About to ask user to process")
		set promptProcessDialog to (choose from list processList of prefs with title AppletName with prompt "Creds expire: " & time string of (credentialsUpdatedTS + credentialsTimeout) & return & return & "Select a process to run:" OK button name "Run" without multiple selections allowed and empty selection allowed)
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
	
	-- 2017-10-18 ( eshagdar ): added quit process
	-- 2017-06-28 ( eshagdar ): created.
	
	try
		set processList to {Â
			"DO NOTHING", Â
			"Full Access Toggle", Â
			"Db Manage", Â
			"Functions Open", Â
			"Security Open", Â
			"Security Save", Â
			"PrivSet - copy settings to other PrivSets", Â
			"New table", Â
			"Data Viewer", Â
			"Clipboard Clear", Â
			"Credentials Update", Â
			"QUIT"}
		
		set oneProcess to promptProcess({processList:processList})
		if oneProcess is equal to "DO NOTHING" or oneProcess is equal to false then
			return true
			
			
		else if oneProcess is equal to "Full Access Toggle" then
			fullAccessToggle({})
			
			
		else if oneProcess is equal to "Db Manage" then
			set fullAccessToggle to fullAccessToggle({ensureMode:"full"})
			tell application "htcLib"
				fmGUI_Menu_OpenDB({})
				windowWaitUntil({windowName:"Manage Database for", whichWindow:"front", windowNameTest:"does not contain", waitCycleDelaySeconds:1, waitCycleMax:30 * minutes})
			end tell
			if modeSwitch of fullAccessToggle then fullAccessToggle({})
			
			
		else if oneProcess is equal to "Functions Open" then
			fullAccessToggle({ensureMode:"full"})
			tell application "htcLib" to return fmGUI_CustomFunctions_Open({})
			
			
		else if oneProcess is equal to "Security Open" then
			fullAccessToggle({ensureMode:"full"})
			tell application "htcLib" to return fmGUI_ManageSecurity_GoToTab_PrivSets(fullAccessCredentials)
			
			
		else if oneProcess is equal to "Security Save" then
			tell application "htcLib"
				fmGUI_AppFrontMost()
				tell application "htcLib" to return fmGUI_ManageSecurity_Save(fullAccessCredentials)
			end tell
			
			
		else if oneProcess is equal to "PrivSet - copy settings to other PrivSets" then
			set fullAccessToggle to fullAccessToggle({ensureMode:"full"})
			privSetLib's copyPrivSetToOthers({})
			if modeSwitch of fullAccessToggle then fullAccessToggle({})
			
			
		else if oneProcess is equal to "New table" then
			display dialog "This process is not yet finished" with title AppletName buttons "OK" default button "OK"
			return true
			
			
		else if oneProcess is equal to "Data Viewer" then
			tell application "htcLib" to return fmGUI_DataViewer_Open(fullAccessCredentials)
			
			
		else if oneProcess is equal to "Clipboard Clear" then
			set the clipboard to null
			return true
			
			
		else if oneProcess is equal to "Credentials Update" then
			return credentialsLib's credentialsUpdate(fullAccessCredentials & userCredentials)
			
			
		else if oneProcess is equal to "QUIT" then
			credentialsLib's credentialsCheck({forceClear:true})
			continue quit
			
			
		else
			return false
		end if
		
	on error errMsg number errNum
		error "unable to runProcess - " & errMsg number errNum
	end try
end runProcess



on fullAccessToggle(prefs)
	-- wrapper for htcLib handler that toggles between full access and user account
	
	-- 2017-10-17 ( eshagdar ): moved function into htcLib and converted this to a wrapper
	try
		tell application "htcLib" to return fmGUI_fullAccessToggle(prefs & fullAccessCredentials & userCredentials)
	on error errMsg number errNum
		error "unable to fullAccessToggle - " & errMsg number errNum
	end try
end fullAccessToggle


