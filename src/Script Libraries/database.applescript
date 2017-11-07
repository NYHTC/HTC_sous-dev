-- HTC sous-dev, privSet library
-- 2017-11-02, Erik Shagdar, NYHTC

(*
	2017-11-02 ( eshagdar ): created.
*)



property name : "database"
property id : "org.nyhtc.sous-dev.database"
property version : "0.1"



on newTable(prefs)
	-- create a new table
	
	-- 2017-11-01 ( eshagdar ): created
	
	try
		set defaultPrefs to {dbName:null, newTableName:null, similarTableName:null, primaryKeyName:null}
		set prefs to prefs & defaultPrefs
		
		set dbName to dbName of prefs
		set newTableName to newTableName of prefs
		set similarTableName to similarTableName of prefs
		set primaryKeyName to primaryKeyName of prefs
		
		
		-- pick up global values from main script
		global appPath
		global fullAccessCredentials
		global newTableAndFields
		global fmObjTrans
		global htcBasic
		
		
		-- get working db name
		if dbName is null then tell application "htcLib" to set dbName to databaseNameOfFrontWindow({fmAppType:"Adv"})
		
		
		-- get table names
		if newTableName is null then
			set newTableDlg to htcBasic's promptUser("Enter the name of the table to create in '" & dbName & "' database:")
			set newTableName to text returned of newTableDlg
			if newTableName is equal to "" then error "You must specify the name of a new table" number -1024
		end if
		tell application "htcLib" to set newTableName to textUpper({str:newTableName})
		
		if similarTableName is null then
			set similarTableDlg to htcBasic's promptUser("Enter the name of the table that '" & newTableName & "' should have the security copied from in '" & dbName & "' database:")
			set similarTableName to text returned of similarTableDlg
			if similarTableName is equal to "" then error "You must specify the name of a new table" number -1024
		end if
		
		
		-- prompt for primary key field name
		if primaryKeyName is null then
			set pkFieldDlg to htcBasic's promptUser("Enter the name of the primary key of '" & newTableName & "' table in '" & dbName & "' database:")
			set primaryKeyName to text returned of pkFieldDlg
		end if
		
		
		-- confirm similar table exists
		tell application "htcLib" to set existingTableNames to fmGUI_ManageDb_ListOfTableNames({stayOpen:true})
		if similarTableName is not in existingTableNames then error "specified table '" & similarTableName & "' does not exist in '" & dbName & "' database" number -1024
		
		
		-- get XML of table/fields
		set pathXMLDir to appPath & "Contents:Resources:XML:"
		set path_XML to pathXMLDir & newTableAndFields
		set XMLtext to read file path_XML
		
		
		-- update placeholders and set to clipboard
		tell application "htcLib"
			set XMLtext to replaceSimple({sourceTEXT:XMLtext, oldChars:"||FULL_TABLE_NAME||", newChars:newTableName})
			if length of primaryKeyName is greater than 0 then set XMLtext to replaceSimple({sourceTEXT:XMLtext, oldChars:"||__pk__||", newChars:primaryKeyName})
		end tell
		set the clipboard to XMLtext
		
		
		-- convert XML to FM object
		clipboardConvertToFMObjects({}) of fmObjTrans
		
		
		-- paste XML and save changes
		tell application "htcLib"
			fmGUI_ManageDb_TableListFocus({})
			fmGUI_PasteFromClipboard()
			fmGUI_ManageDB_Save({})
		end tell
		
		
		-- layouts
		tell application "htcLib"
			fmGUI_ManageLayouts_Edit({layoutName:newTableName & " Basic", layoutOldName:newTableName})
			fmGUI_ManageLayouts_Close({})
		end tell
		
		
		-- security
		tell application "htcLib" to fmGUI_ManageSecurity_CopyTableForAllPrivSets({sourceTable:similarTableName, effectTable:newTableName} & fullAccessCredentials)
		
		
		
		-- prompt to go to table
		
		
		return XMLtext
	on error errMsg number errNum
		error "unable to newTable - " & errMsg number errNum
	end try
end newTable

