-- HTC sous-dev, privSet library
-- 2017-10-05, Erik Shagdar, NYHTC

(*
	2017-10-05 ( eshagdar ): created.
*)



property name : "credentials"
property id : "org.nyhtc.sous-dev.credentials"
property version : "0.1"



on credentialsUpdate(prefs)
	-- prompt user for credentials
	
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
		if userAccountName of prefs is "" then set userAccountName to do shell script "whoami"
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
