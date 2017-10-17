-- HTC sous-dev, privSet library
-- 2017-10-05, Erik Shagdar, NYHTC

(*
	2017-10-05 ( eshagdar ): created
*)



property name : "privSet"
property id : "org.nyhtc.sous-dev.privSet"
property version : "0.1"



on copyPrivSetToOthers(prefs)
	-- copy setting for the currently selected privSet across to all other tenants
	
	-- 2017-10-05 ( eshagdar ): ensure we're in manage security. moved into privSeet library ( out of main ).
	-- 2017-06-28 ( eshagdar ): created.
	
	set defaultPrefs to {processList:{}}
	set prefs to prefs & defaultPrefs
	
	try
		global AppletName
		global fullAccessCredentials
		tell application "htcLib"
			fmGUI_AppFrontMost()
			set frontMostWindowName to fmGUI_NameOfFrontmostWindow()
		end tell
		
		if frontMostWindowName does not start with "Manage Security" then
			tell "htcLib" to fmGUI_ManageSecurity_GoToTab_PrivSets(fullAccessCredentials)
			tell it to activate
			display dialog "Select a privSet and try again." with title AppletName buttons "OK" default button "OK"
			return false
		end if
		
		
		-- ensure row is selected
		try
			tell application "System Events"
				tell application process "FileMaker Pro"
					set selectedPrivSetName to value of static text 1 of (first row of table 1 of scroll area 1 of tab group 1 of window 1 whose selected is true)
				end tell
			end tell
		on error errMsg number errNum
			tell it to activate
			display dialog "You must have a privSet selected to run this process." with title AppletName buttons "OK" default button "OK"
			return false
		end try
		
		
		-- crawl through selected privSet and close it
		tell application "htcLib" to set privSetInfo to fmGUI_ManageSecurity_PrivSet_GetInfo({getAccessInfo:true})
		tell application "System Events"
			tell process "FileMaker Pro"
				click button "Cancel" of window 1
			end tell
		end tell
		
		
		-- get source privSet name and a list of records to loop over to ( potentially ) udpate
		set currentPrivSetName to privSetName of privSetInfo
		if text -2 of currentPrivSetName is "_" then
			set currentPrivSetBaseName to text 1 thru -3 of currentPrivSetName
		else
			error "privSet name does not have an orgNum suffix" number -1024
		end if
		
		tell application "System Events"
			tell process "FileMaker Pro"
				set privSetRecsForBasePrivSetName to every row of table 1 of scroll area 1 of tab group 1 of window 1 whose value of static text 1 begins with currentPrivSetBaseName
			end tell
		end tell
		
		
		-- loop though all privSet for other orgNum
		repeat with onePrivSetToUpdate in privSetRecsForBasePrivSetName
			set onePrivSetToUpdate to contents of onePrivSetToUpdate
			tell application "System Events"
				tell process "FileMaker Pro"
					set onePrivSetNameToUpdate to value of static text 1 of onePrivSetToUpdate
				end tell
			end tell
			
			if onePrivSetNameToUpdate is equal to currentPrivSetName then
				-- skip this privSet since it's our source
			else
				-- update privSet to match source privSet
				tell application "htcLib" to fmGUI_ManageSecurity_PrivSet_Update(fullAccessCredentials & {privSetName:onePrivSetNameToUpdate} & privSetInfo)
			end if
		end repeat
		
		
		
		return privSetInfo
		
	on error errMsg number errNum
		tell it to activate
		error "unable to copyPrivSetToOthers - " & errMsg number errNum
	end try
end copyPrivSetToOthers

