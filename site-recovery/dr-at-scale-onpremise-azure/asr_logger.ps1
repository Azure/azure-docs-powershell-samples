class MigrationLogger {

    [string]$CurrentCommandPath
    [string]$OutputFilePath
    [string]$ScriptName
    [DateTime]$StartDate

    MigrationLogger([string] $CurrentCommandPath) {
        $this.StartDate = Get-Date
        $this.CurrentCommandPath = $CurrentCommandPath
        $this.ScriptName = Split-Path $CurrentCommandPath -Leaf
        $fileName = [string]::Concat("log.", $this.ScriptName, ".", $this.FormatDate($this.StartDate), ".txt")

        $this.OutputFilePath = $this.ReplaceLastSubstring($CurrentCommandPath, $this.ScriptName, $fileName)
    }
    
    [string] FormatDate($date) {
        return $date.ToString("yyyyMMdd_HHmmss")
    }

    [string] FormatCurrentDate() {
        $currentDate = Get-Date
        return $this.FormatDate($currentDate)
    }

    [string] ReplaceLastSubstring([string]$str, [string]$substr, [string]$newstr)
    {
        $lastIndex = $str.LastIndexOf($substr)
        $result = $str.Remove($lastIndex,$substr.Length).Insert($lastIndex,$newstr)
        return $result
    }

    [void] LogError([string] $Message)
    {
        $logDate = $this.FormatCurrentDate()
        $logMessage = [string]::Concat($logDate, "[ERROR]-", $Message)
        $logMessage | Out-File -FilePath $this.OutputFilePath -Append
        Write-Host $logMessage -ForegroundColor Yellow
    }
    
    [void] LogErrorAndThrow([string] $Message)
    {
        $logDate = $this.FormatCurrentDate()
        $logMessage = [string]::Concat($logDate, "[ERROR]-", $Message)
        $logMessage | Out-File -FilePath $this.OutputFilePath -Append
        Write-Error $logMessage
    }
    
    [void] LogTrace([string] $Message)
    {
        $logDate = $this.FormatCurrentDate()
        $logMessage = [string]::Concat($logDate, "[LOG]-", $Message)
        $logMessage | Out-File -FilePath $this.OutputFilePath -Append
        Write-Host $logMessage
    }

}


Function New-AsrLoggerInstance($CommandPath)
{
  return [MigrationLogger]::new($CommandPath)
}

