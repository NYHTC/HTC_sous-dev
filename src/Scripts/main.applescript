-- HTC sous-dev
-- 2017-05-03, Erik Shagdar, NYHTC

-- written against OS X 10.10.5 and FileMaker 15.0.3

(*
	2017-11-08 ( eshagdar ): renamed script library 'database' to 'fmDatabase'.
	2017-11-02 ( eshagdar ): pass prefs thru to sub-handlers. enabled new table process. added 'database' script library
	2017-10-19 ( eshagdar ): open data viewer. open manage DB. 'added Functions Open' process
	2017-10-17 ( eshagdar ): update 'promptProcess' to show credential expiration TS.
	2017-10-16 ( eshagdar ): converted app to source files.
	2017-05-03 ( eshagdar ): created.
*)


property AppletName : "HTC sous-dev"
property appPath : ""
property htcLibURL : "https://github.com/NYHTC/applescript-fm-helper"


property debugMode : false
property logging : false

property orgNumLIST : {1, 2}

property idleTime : 5 * minutes

property credentialsTimeout : 2 * hours
property credentialsUpdatedTS : (current date) - credentialsTimeout
property fullAccessCredentials : {}
property userCredentials : {}

property newTableAndFields : "NewTable.xml"
property fmObjTrans : ""




use htcBasic : script "htcBasic"
use credentialsLib : script "credentials"
use fmSecurity : script "fmSecurity"
use fmDatabase : script "fmDatabase"
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
	
	-- 2017-11-08 ( eshagdar ): no need to activate. the show error handler already does it.
	-- 2017-11-01 ( eshagdar ): don't bother showing error stack if user canceled
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
		
		
		-- get app path
		tell application "Finder" to set appPath to (path to me) as string
		
		
		-- init dependencies
		launchHtcLib({})
		initFmObjTrans({})
		
		
		-- credentials debugging
		if debugMode then htcBasic's debugMsg("mainScript ---" & return & Â
			"fullAccessCredentials: " & htcBasic's coerceToString(fullAccessCredentials) & return & Â
			"userCredentials: " & htcBasic's coerceToString(userCredentials))
		
		
		-- ensure credentials are not outdated
		credentialsLib's credentialsEnsure({})
		
		
		-- prompt user what to do
		set process to item 1 of prefs
		return runProcess({process:process})
	on error errMsg number errNum
		tell application "htcLib" to set errStack to replaceSimple({sourceTEXT:errMsg, oldChars:" - ", newChars:return})
		set ignoreErrorNumList to {-128, -1024, -1719}
		(*
			-128: user cancel
			-1024: generic error
			-1719: assistive device
		*)
		if errNum is not in ignoreErrorNumList then set errStack to errStack & " ( errNum: " & errNum & " )"
		if errNum is not -128 then htcBasic's showUserError(errStack)
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



on initFmObjTrans(prefs)
	-- init fmObjectTranslator
	
	-- 2017-11-02 ( eshagdar ): created
	
	
	try
		set defaultPrefs to {}
		set prefs to prefs & defaultPrefs
		
		
		tell application "Finder"
			set appPath to path to me as string
		end tell
		set fmObjPath to appPath & "Contents:Resources:Scripts:fmObjectTranslator.applescript"
		set fmObjTrans to run script (alias fmObjPath)
		--tell fmObjTransScript to set fmObjTrans to fmObjectTranslator_Instantiate({})
		
		
		return true
	on error errMsg number errNum
		error "unable to initFmObjTrans - " & errMsg number errNum
	end try
end initFmObjTrans



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
	
	-- 2017-11-20 ( eshagdar ): rename 'Table Copy Security' to 'Table Duplicate Security'
	-- 2017-11-02 ( eshagdar ): enabled create table process
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
			"Table Create", Â
			"Table Duplicate Security", Â
			"Table Copy Security for PrivSet", Â
			"Data Viewer", Â
			"Clipboard Clear", Â
			"Credentials Authenticate", Â
			"Credentials Update", Â
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
			
		else if oneProcess is equal to "Table Create" then
			return process_TableNew({})
			
		else if oneProcess is equal to "Table Duplicate Security" then
			return process_TableSecurityDuplicate({})
			
		else if oneProcess is equal to "Table Copy Security for PrivSet" then
			return process_TableSecurityCopy({})
			
		else if oneProcess is equal to "Data Viewer" then
			return process_dataViewerOpen({})
			
		else if oneProcess is equal to "Clipboard Clear" then
			return process_ClipboardClear({})
			
		else if oneProcess is equal to "Credentials Authenticate" then
			return process_credentialsAuth({})
			
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
	
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-17 ( eshagdar ): moved function into htcLib and converted this to a wrapper
	
	
	try
		tell application "htcLib" to return fmGUI_fullAccessToggle(prefs & fullAccessCredentials & userCredentials)
	on error errMsg number errNum
		error "unable to process_fullAccessToggle - " & errMsg number errNum
	end try
end process_fullAccessToggle



on process_manageDB(prefs)
	-- wrapper for opening manage DB
	
	-- 2017-11-20 ( eshagdar ): return process result
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		set fullAccessToggle to process_fullAccessToggle({ensureMode:"full"})
		tell application "htcLib"
			set processResult to fmGUI_Menu_OpenDB(prefs)
			windowWaitUntil({windowName:"Manage Database for", whichWindow:"front", windowNameTest:"does not contain", waitCycleDelaySeconds:1, waitCycleMax:30 * minutes})
		end tell
		if modeSwitch of fullAccessToggle then process_fullAccessToggle({})
		
		return processResult
	on error errMsg number errNum
		error "unable to process_manageDB - " & errMsg number errNum
	end try
end process_manageDB



on process_functionsOpen(prefs)
	-- wrapper for opening custom functions
	
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		process_fullAccessToggle({ensureMode:"full"})
		tell application "htcLib" to return fmGUI_CustomFunctions_Open(prefs)
	on error errMsg number errNum
		error "unable to process_functionsOpen - " & errMsg number errNum
	end try
end process_functionsOpen



on process_securityOpen(prefs)
	-- wrapper for opening security
	
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		process_fullAccessToggle({ensureMode:"full"})
		tell application "htcLib" to return fmGUI_ManageSecurity_GoToTab_PrivSets(prefs & fullAccessCredentials)
	on error errMsg number errNum
		error "unable to process_securityOpen - " & errMsg number errNum
	end try
end process_securityOpen



on process_securitySave(prefs)
	-- wrapper for saving security
	
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		tell application "htcLib"
			fmGUI_AppFrontMost()
			return fmGUI_ManageSecurity_Save(prefs & fullAccessCredentials)
		end tell
	on error errMsg number errNum
		error "unable to process_securitySave - " & errMsg number errNum
	end try
end process_securitySave



on process_PrivSetCopy(prefs)
	-- wrapper for copying a selected privSet
	
	-- 2017-11-20 ( eshagdar ): return process result
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		set fullAccessToggle to process_fullAccessToggle({ensureMode:"full"})
		set processResult to fmSecurity's copyPrivSetToOthers(prefs)
		if modeSwitch of fullAccessToggle then process_fullAccessToggle({})
		
		return processResult
	on error errMsg number errNum
		error "unable to process_PrivSetCopy - " & errMsg number errNum
	end try
end process_PrivSetCopy



on process_TableNew(prefs)
	-- create a new table
	
	-- 2017-11-20 ( eshagdar ): return process result. go into full access mode if needed
	-- 2017-11-01 ( eshagdar ): created
	
	
	try
		set fullAccessToggle to process_fullAccessToggle({ensureMode:"full"})
		set processResult to fmDatabase's newTable(prefs)
		if modeSwitch of fullAccessToggle then process_fullAccessToggle({})
		
		return processResult
	on error errMsg number errNum
		error "unable to process_NewTable - " & errMsg number errNum
	end try
end process_TableNew



on process_TableSecurityDuplicate(prefs)
	-- duplicate privSet access settings from one table into another.
	
	-- 2017-11-20 ( eshagdar ): return process result. go into full access mode if needed
	-- 2017-11-01 ( eshagdar ): created
	
	
	try
		set fullAccessToggle to process_fullAccessToggle({ensureMode:"full"})
		set processResult to fmDatabase's copyPrivSetSettingsForOneTable(prefs)
		if modeSwitch of fullAccessToggle then process_fullAccessToggle({})
		
		return processResult
	on error errMsg number errNum
		error "unable to process_TableSecurityDuplicate - " & errMsg number errNum
	end try
end process_TableSecurityDuplicate



on process_TableSecurityCopy(prefs)
	-- copy settings for the currently selected privSet into the clipbaord.
	
	-- 2017-11-28 ( eshagdar ): created
	
	
	try
		tell application "htcLib"
			with timeout of (30 * 60) seconds
				--get info can cause the appleEvent to time out if there are many tables or complex security
				set privSetInfo to fmGUI_ManageSecurity_PrivSet_GetInfo({} & {getAccessInfo:true})
			end timeout
			fmGUI_ObjectClick_CancelButton({})
		end tell
		set the clipboard to privSetInfo
		
		return privSetInfo
	on error errMsg number errNum
		error "unable to process_TableSecurityDuplicate - " & errMsg number errNum
	end try
end process_TableSecurityCopy



on process_dataViewerOpen(prefs)
	-- wrapper for opening the data viewer
	
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		tell application "htcLib" to return fmGUI_DataViewer_Open(prefs & fullAccessCredentials)
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



on process_credentialsAuth(prefs)
	-- authenticate using current credentials
	
	-- 2017-11-20 ( eshagdar ): created
	
	
	try
		set whichCredential to button returned of htcBasic's showDialog({msg:"Which credentials do you want to authenticate with?", buttonList:{"User", "Full Access", "Cancel"}})
		if whichCredential is "User" then
			tell application "htcLib" to return fmGUI_AuthenticateDialog({accountName:userAccountName of userCredentials, pwd:userPassword of userCredentials})
		else if whichCredential is "Full Access" then
			tell application "htcLib" to return fmGUI_AuthenticateDialog({accountName:fullAccessAccountName of fullAccessCredentials, pwd:fullAccessPassword of fullAccessCredentials})
		end if
	on error errMsg number errNum
		error "unable to process_credentialsUpdate - " & errMsg number errNum
	end try
end process_credentialsAuth



on process_credentialsUpdate(prefs)
	-- wrapper for updating credentials
	
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		return credentialsLib's credentialsUpdate(prefs & fullAccessCredentials & userCredentials)
	on error errMsg number errNum
		error "unable to process_credentialsUpdate - " & errMsg number errNum
	end try
end process_credentialsUpdate



on process_quit(prefs)
	-- wrapper for quiting applet
	
	-- 2017-11-02 ( eshagdar ): pass prefs thru
	-- 2017-10-23 ( eshagdar ): moved from runProcess into a separate handler
	
	
	try
		credentialsLib's credentialsCheck(prefs & {forceClear:true})
		continue quit
	on error errMsg number errNum
		error "unable to process_quit - " & errMsg number errNum
	end try
end process_quit
