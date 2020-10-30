class MigrationLogger {

    [string]$CurrentCommandPath
    [string]$OutputFilePath
    [string]$ScriptName
    [DateTime]$StartDate

    MigrationLogger([string] $CurrentCommandPath) {
        $this.StartDate = Get-Date
        $this.CurrentCommandPath = $CurrentCommandPath
        $this.ScriptName = Split-Path $CurrentCommandPath -Leaf
        # Get the directory path
        $dirPath = Split-Path $CurrentCommandPath -Parent
        $dirPathforLogs = [string]::Concat($dirPath, "\logs")
        $fileName = $null
        #Creates a new directory if it doesnt exist
        if (-not (Test-Path -LiteralPath $dirPathforLogs)) {            
            try {
                New-Item -Path $dirPathforLogs -ItemType Directory -ErrorAction Stop | Out-Null #-Force
                $fileName = [string]::Concat("logs\", "log.", $this.ScriptName, ".", $this.FormatDate($this.StartDate), ".txt")
            }
            catch {                
                $fileName = [string]::Concat("log.", $this.ScriptName, ".", $this.FormatDate($this.StartDate), ".txt")
            }
        }
        else {            
            $fileName = [string]::Concat("logs\", "log.", $this.ScriptName, ".", $this.FormatDate($this.StartDate), ".txt")
        }        

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

    #We are actually not throwing the error as we are assuming that the scripts will be called for multiple items and want other to continue. But if we want 
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


Function New-AzMigrate_LoggerInstance($CommandPath)
{
  return [MigrationLogger]::new($CommandPath)
}