-- HTC sous-dev, helper/basics library
-- 2017-05-03, Erik Shagdar, NYHTC

(*
	2017-05-03 ( eshagdar ): created.
*)



property name : "htcBasic"
property id : "org.nyhtc.sous-dev.htcBasic"
property version : "0.1"



on logToConsole(consoleMsg)
	-- version 1.0, Erik Shagdar
	-- log a message to the console
	
	-- 2017-10-16 ( eshagdar ): created
	
	try
		global AppletName
		tell application "htcLib" to logConsole(AppletName, my coerceToString(consoleMsg))
		
		return true
	on error errMsg number errNum
		error "unable to logToConsole - " & errMsg number errNum
	end try
end logToConsole


on debugMsg(msg)
	-- wrapper handler
	
	-- 2017-10-10 ( eshagdar ): created.
	
	try
		global AppletName
		
		return showDialog({msg:msg, title:AppletName & " DEBUG"})
	on error errMsg number errNum
		error "unable to debugMsg - " & errMsg number errNum
	end try
end debugMsg


on showUserError(msg)
	-- wrapper handler
	
	-- 2017-10-10 ( eshagdar ): created.
	
	try
		global AppletName
		
		return showDialog({msg:msg, title:AppletName & " ERROR"})
	on error errMsg number errNum
		error "unable to showUserError - " & errMsg number errNum
	end try
end showUserError


on promptUser(msg)
	-- wrapper handler
	
	-- 2017-11-01 ( eshagdar ): created.
	
	try
		global AppletName
		
		return showDialog({msg:msg, title:AppletName, shouldPrompt:true})
	on error errMsg number errNum
		error "unable to promptUser - " & errMsg number errNum
	end try
end promptUser


on promptUserWithDefaultAnswer(prefs)
	-- wrapper handler, contains a default answer.
	
	-- 2017-11-07 ( eshagdar ): created.
	
	try
		set defaultPrefs to {msg:null, defaultAnswer:null}
		set prefs to prefs & defaultPrefs
		
		
		global AppletName
		
		
		return showDialog({msg:msg of prefs, title:AppletName, defaultAnswer:defaultAnswer of prefs, shouldPrompt:true})
	on error errMsg number errNum
		error "unable to promptUser - " & errMsg number errNum
	end try
end promptUserWithDefaultAnswer


on showDialog(prefs)
	-- show the user a dialog
	
	-- 2017-11-08 ( eshagdar ): updated param name to defaultAnswer, init its value to an empty sting if it's null.
	-- 2017-11-01 ( eshagdar ): added option to prompt user for an answer
	-- 2017-10-10 ( eshagdar ): created.
	
	try
		global AppletName
		
		set defaultPrefs to {msg:null, title:AppletName, buttonList:{"OK", "Cancel"}, shouldPrompt:false, defaultAnswer:""}
		set prefs to prefs & defaultPrefs
		set defaultAnswer to defaultAnswer of prefs
		
		tell it to activate
		if shouldPrompt of prefs or defaultAnswer is not equal to "" then
			if defaultAnswer is null then set defaultAnswer to ""
			return display dialog coerceToString(msg of prefs) with title title of prefs default answer defaultAnswer buttons (buttonList of prefs) default button item 1 of buttonList of prefs
		else
			return display dialog coerceToString(msg of prefs) with title title of prefs buttons (buttonList of prefs) default button item 1 of buttonList of prefs
		end if
	on error errMsg number errNum
		error "unable to showDialog - " & errMsg number errNum
	end try
end showDialog


on systemNotification(prefs)
	-- version 1.0
	-- take from htcLib
	
	set defaultPrefs to {msg:"", msgTitle:"", msgSubtitle:"", msgSound:"default", noSound:null}
	set prefs to prefs & defaultPrefs
	
	if noSound of prefs is not null then
		display notification msg of prefs with title msgTitle of prefs subtitle msgSubtitle of prefs
	else
		display notification msg of prefs with title msgTitle of prefs subtitle msgSubtitle of prefs sound name msgSound of prefs
	end if
	
end systemNotification



on coerceToString(incomingObject)
	-- version 2.2
	
	if class of incomingObject is string then
		set {text:incomingObject} to (incomingObject as string)
		return incomingObject
	else if class of incomingObject is integer then
		set {text:incomingObject} to (incomingObject as string)
		return incomingObject as string
	else if class of incomingObject is real then
		set {text:incomingObject} to (incomingObject as string)
		return incomingObject as string
	else if class of incomingObject is Unicode text then
		set {text:incomingObject} to (incomingObject as string)
		return incomingObject as string
	else
		-- LIST, RECORD, styled text, or unknown
		try
			try
				set some_UUID_Property_54F827C7379E4073B5A216BB9CDE575D of "XXXX" to "some_UUID_Value_54F827C7379E4073B5A216BB9CDE575D"
				
				-- GENERATE the error message for a known 'object' (here, a string) so we can get 
				-- the 'lead' and 'trail' part of the error message
			on error errMsg number errNum
				set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {"\"XXXX\""}}
				set {errMsgLead, errMsgTrail} to text items of errMsg
				set AppleScript's text item delimiters to oldDelims
			end try
			
			-- now, generate error message for the SPECIFIED object: 
			set some_UUID_Property_54F827C7379E4073B5A216BB9CDE575D of incomingObject to "some_UUID_Value_54F827C7379E4073B5A216BB9CDE575D"
			
			
		on error errMsg
			if errMsg starts with "System Events got an error: Can’t make some_UUID_Property_54F827C7379E4073B5A216BB9CDE575D of " and errMsg ends with "into type specifier." then
				set errMsgLead to "System Events got an error: Can’t make some_UUID_Property_54F827C7379E4073B5A216BB9CDE575D of "
				set errMsgTrail to " into type specifier."
				
				set {od, AppleScript's text item delimiters} to {AppleScript's text item delimiters, errMsgLead}
				
				set objectString to text item 2 of errMsg
				set AppleScript's text item delimiters to errMsgTrail
				
				set objectString to text item 1 of objectString
				set AppleScript's text item delimiters to od
				
				
				
			else
				--tell me to log errMsg
				set objectString to errMsg
				
				if objectString contains errMsgLead then
					set {od, AppleScript's text item delimiters} to {AppleScript's text item delimiters, errMsgLead}
					set objectString to text item 2 of objectString
					set AppleScript's text item delimiters to od
				end if
				
				if objectString contains errMsgTrail then
					set {od, AppleScript's text item delimiters} to {AppleScript's text item delimiters, errMsgTrail}
					set AppleScript's text item delimiters to errMsgTrail
					set objectString to text item 1 of objectString
					set AppleScript's text item delimiters to od
				end if
				
				--set {text:objectString} to (objectString as string) -- what does THIS do?
			end if
		end try
		
		return objectString
	end if
end coerceToString


