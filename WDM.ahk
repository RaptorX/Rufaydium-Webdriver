; WDM aka Web Driver management Class for Rufaydium.ahk 
; I am upto/will add support update auto download supporting Webdriver when browser gets update
; By Xeo786

Class RunDriver
{
	__New(Location,Parameters:= "--port=9515")
	{
		SplitPath, Location,Name,Dir,,DriverName
		this.Dir := Dir ? Dir : A_ScriptDir
		this.exe := Name
		this.param := Parameters
		This.Target := Location " " chr(34) Parameters chr(34)
		this.Name := DriverName
		switch this.Name
		{
			case "chromedriver" :
				this.Options := "goog:chromeOptions"
				this.browser := "chrome"

			case "msedgedriver" : 
				this.Options := "ms:edgeOptions"
				this.browser := "msedge"
		}
		
		if !FileExist(Location)
			Location := this.GetDriver()

		if !FileExist(Location)
		{
			Msgbox,64,Rufaydium WebDriver Support,Unable to download driver`nRufaydium exitting
			Exitapp
		}

		if RegExMatch(this.param,"--port=(\d+)",port)
			This.Port := Port1
		else
		{
			Msgbox,64,"Rufaydium WebDriver Support,Unable to download driver from`nURL :" this.DriverUrl "`nRufaydium exitting"
			exitapp
		}
		
		PID := this.GetPIDbyName(Name)
		if PID
		{
			this.PID := PID
		}
		else			
			this.Launch()
	}
	
	__Delete()
	{
		;this.exit()
	}
	
	exit()
	{
		Process, Close, % This.PID
	}
	
	Launch()
	{
		Run % this.Target,,Hide,PID
		Process, Wait, % PID
		this.PID := PID
	}
	
	help(Location)
	{
		Run % comspec " /k " chr(34) Location chr(34) " --help > dir.txt",,Hide,PID
		while !FileExist(A_ScriptDir "\dir.txt")
			sleep, 200
		sleep, 200
		FileRead, Content, dir.txt
		while FileExist(A_ScriptDir "\dir.txt")
			FileDelete, % A_ScriptDir "\dir.txt"
		Process, Close, % PID
		return Content
	}
	
	visible
	{
		get
		{
			return this.visibility
		}
		
		set
		{
			if(value = 1) and !this.visibility
			{
				winshow, % "ahk_pid " this.pid
				this.visibility := 1
			}
			else
			{
				winhide, % "ahk_pid " this.pid
				this.visibility := 0
			}
		}
	}
	
	; thanks for AHK_user for driver auto-download suggestion and his code https://www.autohotkey.com/boards/viewtopic.php?f=6&t=102616&start=60#p460812
	GetDriver(Version="STABLE",bit="32")
	{
		switch this.Name
		{
			case "chromedriver" :
				this.zip := this.dir "chromedriver_win32.zip"
				if RegExMatch(Version,"Chrome version ([\d.]+).*\n.*browser version is (\d+.\d+.\d+)",bver)
					uri := "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"  bver2
				else
					uri := "https://chromedriver.storage.googleapis.com/LATEST_RELEASE", bver1 := "unknown"
				
				DriverVersion := this.GetVersion(uri)
				this.DriverUrl := "https://chromedriver.storage.googleapis.com/" DriverVersion "/" this.zip
			
			case "msedgedriver" :
				if instr(bit,"64")
					this.zip := this.dir "edgedriver_win64.zip"
				else 
					this.zip := this.dir "edgedriver_win32.zip" 

				if RegExMatch(Version,"version ([\d.]+).*\n.*browser version is (\d+)",bver)
					uri := "https://msedgedriver.azureedge.net/LATEST_" "RELEASE_" bver2
				else if(Version != "STABLE")
					uri := "https://msedgedriver.azureedge.net/LATEST_RELEASE_" Version
				else
					uri := "https://msedgedriver.azureedge.net/LATEST_" Version, bver1 := "unknown"

				DriverVersion := this.GetVersion(uri) ; Thanks RaptorX fixing Issues GetEdgeDrive
				this.DriverUrl := "https://msedgedriver.azureedge.net/" DriverVersion "/" this.zip
		} 
		if InStr(this.DriverVersion, "NoSuchKey"){
			MsgBox,16,Testing,Error`nDriverVersion
			return false
		}
		
		if !FileExist(this.Dir "\Backup")
			FileCreateDir, % this.Dir "\Backup"
		
		while FileExist(this.Dir "\" this.exe)
		{
			Process, Close, % this.GetPIDbyName(this.exe)
			FileMove, % this.Dir "\" this.exe, % this.Dir "\Backup\" this.name " Version " bver1 ".exe", 1
		}
		if this.dir
			this.zip := this.dir "\" this.zip
		this.DownloadnExtract()
	}
	
	GetVersion(uri)
	{
		WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		WebRequest.Open("GET", uri, false)
		WebRequest.SetRequestHeader("Content-Type","application/json")
		WebRequest.Send()
		if url ~= "msedge"
		{
			loop, % WebRequest.GetResponseHeader("Content-Length") ;loop over  responsbody 1 byte at a time
				text .= chr(bytes[A_Index-1]) ;lookup each byte and assign a charter
			return SubStr(text, 3)
		}	
		else
			return WebRequest.responseText
	}

	DownloadnExtract()
	{
		static fso := ComObjCreate("Scripting.FileSystemObject")
		URLDownloadToFile, % this.DriverUrl,  % this.zip
		AppObj := ComObjCreate("Shell.Application")
		FolderObj := AppObj.Namespace(this.zip)	
		FileObj := FolderObj.ParseName(this.exe)
		AppObj.Namespace(this.Dir "\").CopyHere(FileObj, 4|16)
		FileDelete, % this.zip
		if this.Dir
			return this.Dir "\" this.exe
		else
			return this.exe
	}

	GetPIDbyName(name) 
	{
		static wmi := ComObjGet("winmgmts:\\.\root\cimv2")
		for Process in wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name = '" name "'")
			return Process.processId
	}
}



