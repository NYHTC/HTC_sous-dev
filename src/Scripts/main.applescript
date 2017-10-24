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
property htcLibURL : "https://github.com/NYHTC/applescript-fm-helper"


property debugMode : false
property logging : false

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



on run prefs
	if logging then htcBasic's logToConsole("Here I am")
	mainScript(prefs)
end run


on reopen prefs
	mainScript(prefs)
end reopen


on idle
	credentialsLib's credentialsCheck({})
	return idleTime -- sets idle time to specified time ( instead of the default of 30 seconds )
end idle


on quit
	process_quit({})
end quit



on mainScript(prefs)
	-- main script to determine what to run
	
	-- 2017-10-23 ( eshagdar ): added prefs. moved processes into separate handlers.
	-- 2017-xx-xx ( eshagdar ): created
	
	
	try
		-- pick up prefs, if specified
		set defaultPrefs to {null}
		try
			if class of prefs is script or prefs is equal to {} then set prefs to defaultPrefs
		on error
			set prefs to defaultPrefs
		end try
		
		-- launch htcLib
		launchHtcLib({})
		
		
		-- credentials debugging
		if debugMode then htcBasic's debugMsg("mainScript ---" & return & �
			"fullAccessCredentials: " & htcBasic's coerceToString(fullAccessCredentials) & return & �
			"userCredentials: " & htcBasic's coerceToString(userCredentials))
		
		
		-- ensure credentials are not outdated
		credentialsLib's credentialsEnsure({})
		
		
		-- prompt user what to do
		set process to item 1 of prefs
		return runProcess({process:process})
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
	
	try
		if logging then htcBasic's logToConsole("launching htcLib")
		tell application "htcLib" to launch
	on error errMsg number errNum
		set missingAppDialog to display dialog "You do Not have the htcLib installed." with title AppletName buttons {"Cancel", openName} default button openName
		if button returned of missingAppDialog is openName then open location htcLibURL
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
		set processList to {�
			"DO NOTHING", �
			"Full Access Toggle", �
			"Db Manage", �
			"Functions Open", �
			"Security Open", �
			"Security Save", �
			"PrivSet - copy settings to other PrivSets", �
			"New table", �
			"Data Viewer", �
			"Clipboard Clear", �
			"Credentials Update", �
			"QUIT"}
		set oneProcess to promptProcess({processList:processList})
		
		
		if oneProcess is equal to "DO NOTHING" or oneProcess is equal to false then
			return true
			
			
		else if oneProcess is equal to "Full Access Toggle" then
			return process_fullAccessToggle({})
			
			
		else if oneProcess is equal to "Db Manage" then
			return process_manageDB({})
			
			
		else if oneProcess is equal to "Functions Open" then
			return process_functionsOpen({})
			
			
		else if oneProcess is equal to "Security Open" then
			return process_securityOpen({})
			
			
		else if oneProcess is equal to "Security Save" then
			return process_securitySave({})
			
			
		else if oneProcess is equal to "PrivSet - copy settings to other PrivSets" then
			return process_PrivSetCopy({})
			
			
		else if oneProcess is equal to "New table" then
			display dialog "This process is not yet finished" with title AppletName buttons "OK" default button "OK"
			return true
			
			
		else if oneProcess is equal to "Data Viewer" then
			return process_dataViewerOpen({})
			
			
		else if oneProcess is equal to "Clipboard Clear" then
			return process_ClipboardClear({})
			
			
		else if oneProcess is equal to "Credentials Update" then
			return process_credentialsUpdate({})
			
			
		else if oneProcess is equal to "QUIT" then
			return process_quit({})
			
			
		else
			error "unknown process '" & oneProcess & "'" number -1024
		end if
	on error errMsg number errNum
		error "unable to runProcess - " & errMsg number errNum
	end try
end runProcess



on process_fullAccessToggle(prefs)
	-- wrapper for htcLib handler that toggles between full access and user account
	
	-- 2017-10-17 ( eshagdar ): moved function into htcLib and converted this to a wrapper
	
	
	try
		tell application "htcLib" to return fmGUI_fullAccessToggle(prefs & fullAccessCredentials & userCredentials)
	on error errMsg number errNum
		error "unable to process_fullAccessToggle - " & errMsg number errNum
	end try
end process_fullAccessToggle



on process_manageDB(prefs)
	-- wrapper for opening manage DB
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		set fullAccessToggle to process_fullAccessToggle({ensureMode:"full"})
		tell application "htcLib"
			fmGUI_Menu_OpenDB({})
			windowWaitUntil({windowName:"Manage Database for", whichWindow:"front", windowNameTest:"does not contain", waitCycleDelaySeconds:1, waitCycleMax:30 * minutes})
		end tell
		if modeSwitch of fullAccessToggle then process_fullAccessToggle({})
		
		return true
	on error errMsg number errNum
		error "unable to process_manageDB - " & errMsg number errNum
	end try
end process_manageDB



on process_functionsOpen(prefs)
	-- wrapper for opening custom functions
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		fullAccessToggle({ensureMode:"full"})
		tell application "htcLib" to return fmGUI_CustomFunctions_Open({})
	on error errMsg number errNum
		error "unable to process_functionsOpen - " & errMsg number errNum
	end try
end process_functionsOpen



on process_securityOpen(prefs)
	-- wrapper for opening security
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		fullAccessToggle({ensureMode:"full"})
		tell application "htcLib" to return fmGUI_ManageSecurity_GoToTab_PrivSets(fullAccessCredentials)
	on error errMsg number errNum
		error "unable to process_securityOpen - " & errMsg number errNum
	end try
end process_securityOpen



on process_securitySave(prefs)
	-- wrapper for saving security
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		tell application "htcLib"
			fmGUI_AppFrontMost()
			return fmGUI_ManageSecurity_Save(fullAccessCredentials)
		end tell
	on error errMsg number errNum
		error "unable to process_securitySave - " & errMsg number errNum
	end try
end process_securitySave



on process_PrivSetCopy(prefs)
	-- wrapper for copying a selected privSet
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		set fullAccessToggle to process_fullAccessToggle({ensureMode:"full"})
		privSetLib's copyPrivSetToOthers({})
		if modeSwitch of fullAccessToggle then process_fullAccessToggle({})
	on error errMsg number errNum
		error "unable to process_PrivSetCopy - " & errMsg number errNum
	end try
end process_PrivSetCopy



on process_dataViewerOpen(prefs)
	-- wrapper for opening the data viewer
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		tell application "htcLib" to return fmGUI_DataViewer_Open(fullAccessCredentials)
	on error errMsg number errNum
		error "unable to process_dataViewerOpen - " & errMsg number errNum
	end try
end process_dataViewerOpen



on process_ClipboardClear(prefs)
	-- wrapper for clearing the clipboard
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		set the clipboard to null
		return true
	on error errMsg number errNum
		error "unable to process_ClipboardClear - " & errMsg number errNum
	end try
end process_ClipboardClear



on process_credentialsUpdate(prefs)
	-- wrapper for updating credentials
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		return credentialsLib's credentialsUpdate(fullAccessCredentials & userCredentials)
	on error errMsg number errNum
		error "unable to process_credentialsUpdate - " & errMsg number errNum
	end try
end process_credentialsUpdate



on process_quit(prefs)
	-- wrapper for quiting applet
	
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		credentialsLib's credentialsCheck({forceClear:true})
		continue quit
	on error errMsg number errNum
		error "unable to process_quit - " & errMsg number errNum
	end try
end process_quit