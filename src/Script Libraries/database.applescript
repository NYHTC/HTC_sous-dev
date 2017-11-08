-- HTC sous-dev, privSet library
-- 2017-11-02, Erik Shagdar, NYHTC

(*
	2017-11-02 ( eshagdar ): created.
*)



property name : "database"
property id : "org.nyhtc.sous-dev.database"
property version : "0.1"



on promptTableName(prefs)
	-- prompt for a table name
	-- returns a record of a table name.
	
	-- 2017-11-07 ( eshagdar ): moved out of creating new table handler. returns a table name.
	
	try
		set defaultPrefs to {msg:null, defaultAnswer:null}
		set prefs to prefs & defaultPrefs
		
		-- pick up global values from main script
		global htcBasic
		
		
		-- get name of table
		set tableDlg to htcBasic's promptUserWithDefaultAnswer({msg:msg of prefs, defaultAnswer:defaultAnswer of prefs})
		set tableName to text returned of tableDlg
		if tableName is "" then error "You must specify the name of a table" number -1024
		
		return {tableName:tableName}
	on error errMsg number errNum
		error "unable to promptTableName - " & errMsg number errNum
	end try
end promptTableName



on ensureTableNames(prefs)
	-- ensures a source and effect table name
	
	-- 2017-11-07 ( eshagdar ): moved out of creating new table handler. each table name is tested for empty ( in addition to previously being tested for null ). tables are called 'source' and 'effect' instead of 'new' and 'similar'.
	
	try
		set defaultPrefs to {sourceTable:null, effectTable:null, sourceMessage:null, effectMessage:null}
		set prefs to prefs & defaultPrefs
		
		set sourceTable to sourceTable of prefs
		set effectTable to effectTable of prefs
		set sourceMessage to sourceMessage of prefs
		set effectMessage to effectMessage of prefs
		
		
		-- get db name ( if we have a blank message )
		if sourceMessage is null or effectMessage is null then tell application "htcLib" to set dbName to databaseNameOfFrontWindow({fmAppType:"Adv"})
		
		
		-- get name of the EFFECT table ( table being created/modified, etc )
		if effectMessage is null then set effectMessage to "Enter the name of the table to CHANGE the security in '" & dbName & "' database:"
		if effectTable is equal to "" then set effectTable to tableName of promptTableName({msg:effectMessage, defaultAnswer:effectTable})
		tell application "htcLib" to set effectTable to textUpper({str:effectTable})
		
		
		-- get name of SOURCE table ( table whose security is being copied from )
		if sourceMessage is null then set sourceMessage to "Enter the name of the SOURCE table in '" & dbName & "' database:"
		if sourceTable is equal to "" then set sourceTable to tableName of promptTableName({msg:sourceMessage, defaultAnswer:sourceTable})
		
		
		return {sourceTable:sourceTable, effectTable:effectTable}
	on error errMsg number errNum
		error "unable to ensureTableNames - " & errMsg number errNum
	end try
end ensureTableNames



on copyPrivSetSettingsForOneTable(prefs)
	-- ensures table names are specified, then updates the effect table for each privSet
	
	-- 2017-11-07 ( eshagdar ): created.
	
	try
		set defaultPrefs to {sourceTable:null, effectTable:null, sourceMessage:null, effectMessage:null}
		set prefs to prefs & defaultPrefs
		
		
		-- pick up global values from main script
		global fullAccessCredentials
		
		
		set promptTableInfo to ensureTableNames(prefs)
		set sourceTable to sourceTable of promptTableInfo
		set effectTable to effectTable of promptTableInfo
		
		
		tell application "htcLib" to fmGUI_ManageSecurity_CopyTableForAllPrivSets({sourceTable:sourceTable, effectTable:effectTable} & fullAccessCredentials)
		
		
		return true
	on error errMsg number errNum
		error "unable to copyPrivSetSettingsForOneTable - " & errMsg number errNum
	end try
end copyPrivSetSettingsForOneTable



on newTable(prefs)
	-- create a new table in the current file. also append the name of created TO with 'basic'. update the security to match the source table.
	
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
		global newTableAndFields
		global fmObjTrans
		global htcBasic
		
		
		-- get db nam )
		if dbName is null then tell application "htcLib" to set dbName to databaseNameOfFrontWindow({fmAppType:"Adv"})
		
		set effectMessage to "Enter the name of the table to create in '" & dbName & "' database:"
		set sourceMessage to "Enter the name of the table that the new table should have the security copied from:"
		set promptTableInfo to ensureTableNames({sourceTable:similarTableName, effectTable:newTableName, sourceMessage:sourceMessage, effectMessage:effectMessage})
		set newTableName to effectTable of promptTableInfo
		set similarTableName to sourceTable of promptTableInfo
		
		
		-- prompt for primary key field name
		set primaryKeyName to primaryKeyName of prefs
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
		copyPrivSetSettingsForOneTable({dbName:dbName, effectTable:newTableName, sourceTable:similarTableName})
		
		
		
		-- prompt to go to table
		
		
		return true
	on error errMsg number errNum
		error "unable to newTable - " & errMsg number errNum
	end try
end newTable






