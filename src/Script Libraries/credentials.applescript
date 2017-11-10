-- HTC sous-dev, FM security library
-- 2017-10-05, Erik Shagdar, NYHTC

(*
	2017-10-05 ( eshagdar ): created.
*)



property name : "credentials"
property id : "org.nyhtc.sous-dev.credentials"
property version : "0.1"



on credentialsCheck(prefs)
	-- clear credentials if past the timeout
	
	-- 2017-10-18 ( eshagdar ): moved to credentials library
	-- 2017-10-10 ( eshagdar ): added forceClear option.
	-- 2017-05-03 ( eshagdar ): first created.
	
	try
		set defaultPrefs to {forceClear:false}
		set prefs to prefs & defaultPrefs
		
		
		-- pick up global values from main script
		global debugMode
		global credentialsTimeout
		global credentialsUpdatedTS
		global fullAccessCredentials
		global userCredentials
		
		global htcBasic
		
		--if debugMode then htcBasic's debugMsg("credentialsCheck prefs: " & htcBasic's coerceToString(prefs))
		
		set nowTS to (current date)
		set expireTS to (credentialsUpdatedTS + credentialsTimeout)
		
		(*
		if debugMode then htcBasic's debugMsg("001 - " & Â
			"nowTS: " & nowTS & return & Â
			"credentialsUpdatedTS: " & credentialsUpdatedTS & return & Â
			"expires: " & (credentialsUpdatedTS + credentialsTimeout) & return & Â
			"fullCredentials: " & htcBasic's coerceToString(fullAccessCredentials) & return & Â
			"userCredentials: " & htcBasic's coerceToString(userCredentials))
		*)
		
		if forceClear of prefs then
			set fullAccessCredentials to {}
			set userCredentials to {}
			set credentialsUpdatedTS to (nowTS - credentialsTimeout)
			
		else if nowTS > expireTS then
			try
				set fullAccessCredentials to {fullAccessPassword:null} & fullAccessCredentials
				set userCredentials to {userPassword:null} & userCredentials
			on error
				set fullAccessCredentials to {}
				set userCredentials to {}
			end try
			set credentialsUpdatedTS to nowTS
			
		end if
		
		return true
	on error errMsg number errNum
		error "unable to credentialsCheck - " & errMsg number errNum
	end try
end credentialsCheck



on credentialsEnsure(prefs)
	-- ensure credentials are set
	
	-- 2017-10-18 ( eshagdar ): moved to credentials library
	-- 2017-05-03 ( eshagdar ): first created.
	
	try
		set defaultPrefs to {}
		set prefs to prefs & defaultPrefs
		
		
		-- pick up global values from main script
		global fullAccessCredentials
		global userCredentials
		
		
		credentialsCheck({})
		
		try
			set credentialsList to fullAccessCredentials & userCredentials
			if credentialsList is equal to {} then error "credentials need to be set"
			if fullAccessPassword of credentialsList is null then error "empty full access password"
			if userPassword of credentialsList is null then error "empty user password"
		on error errMsg number errNum
			credentialsUpdate(fullAccessCredentials & userCredentials)
		end try
		
		return true
	on error errMsg number errNum
		error "unable to credentialsEnsure - " & errMsg number errNum
	end try
end credentialsEnsure



on credentialsUpdate(prefs)
	-- prompt user for credentials
	
	-- 2017-10-18 ( eshagdar ): setting fullAccessAccountName needs an else ( default value ).
	--2017-10-10 ( eshagdar ): retain previously entered full account and user name.
	-- 2017-10-05 ( eshagdar ): moved into credentials library ( out of main ).
	-- 2017-08-29 ( eshagdar ): store credentials as records instead of a series of strings
	-- 2017-05-03 ( eshagdar ): first created.
	
	try
		set defaultPrefs to {fullAccessAccountName:"", userAccountName:""}
		set prefs to prefs & defaultPrefs
		
		
		-- pick up global values from main script
		global fullAccessCredentials
		global userCredentials
		global credentialsUpdatedTS
		
		
		-- get full-access credentials
		set promptAccount_full to (display dialog "Enter the Full-Access account name:" with title "Authentication" default answer fullAccessAccountName of prefs buttons {"Cancel", "OK"} default button "OK")
		set fullAccessAccount to text returned of promptAccount_full
		
		set promptPassword_full to (display dialog "Enter the password for '" & fullAccessAccount & "':" with title "Authentication" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer)
		set fullAccessPassword to text returned of promptPassword_full
		set fullAccessCredentials to {fullAccessAccountName:fullAccessAccount, fullAccessPassword:fullAccessPassword}
		
		
		-- get user credentials
		if userAccountName of prefs is "" then
			set userAccountName to do shell script "whoami"
		else
			set userAccountName to userAccountName of prefs
		end if
		set promptAccount_user to (display dialog "Enter your account name:" with title "Authentication" default answer userAccountName buttons {"Cancel", "OK"} default button "OK")
		set userAccount to text returned of promptAccount_user
		
		set promptPassword_user to (display dialog "Enter the password for '" & userAccount & "':" with title "Authentication" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer)
		set userPassword to text returned of promptPassword_user
		set userCredentials to {userAccountName:userAccount, userPassword:userPassword}
		
		
		-- update last updated TS
		set credentialsUpdatedTS to current date
		
		
		return true --{fullAccessCredentials:fullAccessCredentials, userCredentials:userCredentials, updateTS:credentialsUpdatedTS}
	on error errMsg number errNum
		error "unable to credentialsUpdate - " & errMsg number errNum
	end try
end credentialsUpdate


