$logFilePath = "C:\\startup_log.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"Hi ${user} $timestamp" | Out-File -FilePath $logFilePath -Append