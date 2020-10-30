class CsvProcessor
{
    [psobject]$Logger
    [psobject]$ProcessItemFunction

    CsvProcessor($logger, $processItemFunction)
    {
        $this.Logger = $logger
        if($processItemFunction)
        {
            $this.ProcessItemFunction = $processItemFunction
        }
    }

    [psobject] LoadCsv($CsvFilePath)
    {
        $resolvedCsvPath = Resolve-Path -LiteralPath $CsvFilePath
        $csvObj = Import-Csv $resolvedCsvPath -Delimiter ','
        return $csvObj
    }

    [string] FormatDate($date) {
        return $date.ToString("yyyyMMdd_HHmmss")
    }
    
    [string] ReplaceLastSubstring([string]$str, [string]$substr, [string]$newstr)
    {
        $lastIndex = $str.LastIndexOf($substr)
        $result = $str.Remove($lastIndex,$substr.Length).Insert($lastIndex,$newstr)
        return $result
    }

    [string] GetCsvOutputPath($resolvedCsvPath)
    {
        $startDate = $this.Logger.StartDate
        $scriptName = $this.Logger.ScriptName
        $csvFileName = Split-Path $resolvedCsvPath -Leaf
        # Get the directory path
        $dirPath = Split-Path $resolvedCsvPath -Parent
        $dirPathforLogs = [string]::Concat($dirPath, "\logs")

        $CsvOutputFileName = $null
        #Creates a new directory if it doesnt exist
        if (-not (Test-Path -LiteralPath $dirPathforLogs)) {            
            try {
                New-Item -Path $dirPathforLogs -ItemType Directory -ErrorAction Stop | Out-Null #-Force
                $this.Logger.LogTrace("Created a New directory for output csv file: '$($dirPathforLogs)'")
                $CsvOutputFileName = [string]::Concat("logs\", "out.", $scriptName, ".", $csvFileName, ".", $this.FormatDate($startDate), ".csv")
            }
            catch {                
                $this.Logger.LogError("We will continue to log in the out csv file location where the input/master csv file existed as we are unable to create directory '$($dirPathforLogs)'")
                $CsvOutputFileName = [string]::Concat("out.", $scriptName, ".", $csvFileName, ".", $this.FormatDate($startDate), ".csv")                
            }
        }
        else {
            $CsvOutputFileName = [string]::Concat("logs\", "out.", $scriptName, ".", $csvFileName, ".", $this.FormatDate($startDate), ".csv")
            $this.Logger.LogTrace("Directory already exist: '$($dirPathforLogs)'")
        }
        
        $CsvOutputFilePath = $this.ReplaceLastSubstring($resolvedCsvPath, $csvFileName, $CsvOutputFileName)
        return $CsvOutputFilePath
    }

    [void] ProcessFile($CsvFilePath)
    {
        $this.Logger.LogTrace("[START]-Processing CsvFile '$($CsvFilePath)'")

        $resolvedCsvPath = Resolve-Path -LiteralPath $CsvFilePath
        $this.Logger.LogTrace("Loading Csv file '$($resolvedCsvPath)'")
        $csvObj = $this.LoadCsv($CsvFilePath)

        $CsvOutputFilePath = $this.GetCsvOutputPath($resolvedCsvPath)
        $this.Logger.LogTrace("Csv output report file: '$($CsvOutputFilePath)'")

        $MachineItemArray = New-Object System.Collections.Generic.List[System.Object]
        foreach ($csvItem in $csvObj)
        {
            $reportItemInfo = [PSCustomObject]@{
                AZMIGRATEPROJECT_SUBSCRIPTION_ID = $($csvItem.AZMIGRATEPROJECT_SUBSCRIPTION_ID)
                AZMIGRATEPROJECT_RESOURCE_GROUP_NAME = $($csvItem.AZMIGRATEPROJECT_RESOURCE_GROUP_NAME)
                AZMIGRATEPROJECT_NAME = $($csvItem.AZMIGRATEPROJECT_NAME)
                Machine = $($csvItem.SOURCE_MACHINE_NAME)
                Exception = $null
            }
            try {
                $this.EnsureSubscription($csvItem.AZMIGRATEPROJECT_SUBSCRIPTION_ID)
                $this.PrintSettings($csvItem)            
                $this.ProcessItemFunction.Invoke($this, $csvItem, $reportItemInfo)
            } catch {
                $this.Logger.LogError("Exception processing item")
                $exceptionMessage = $_ | Out-String
                $this.Logger.LogError($exceptionMessage)

                $reportItemInfo.Exception = "EXCEPTION PROCESSING ITEM"
            }
            $MachineItemArray.Add($reportItemInfo)
        }
        $this.Logger.LogTrace("Creating Csv reporting output '$($CsvOutputFilePath)'")
        $MachineItemArray.ToArray() | Export-Csv -LiteralPath $CsvOutputFilePath -Delimiter ',' -NoTypeInformation

        $this.Logger.LogTrace("[FINISH]-CsvFile: '$($CsvFilePath)'")
    }

    [void] EnsureSubscription($subscriptionId)
    {
        $this.Logger.LogTrace("Checking if current subscription equals to '$($subscriptionId)'")
        $currentContext = Get-AzContext
        $currentSubscription = $currentContext.Subscription
        if ($currentSubscription.Id -ne $subscriptionId)
        {
            $this.Logger.LogTrace("Setting context subscription '$($subscriptionId)'")
            Set-AzContext -Subscription $subscriptionId
            $currentContext = Get-AzContext
            $currentSubscription = $currentContext.Subscription
            if ($currentSubscription.Id -ne $subscriptionId)
            {
                $this.Logger.LogErrorAndThrow("SubscriptionId '$($subscriptionId)' is not selected as current default subscription")
            }
        } else {
            $this.Logger.LogTrace("Subscription '$($subscriptionId)' is already selected")
        }
    }

    [void] PrintSettings($csvItem)
    {
        $this.Logger.LogTrace("---BEGIN ITEM DATA---")
        $propertyNames = $csvItem | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name #| Select-Object -Unique
        foreach ($propertyName in $propertyNames) {
            $propertyValue = $csvItem.$($propertyName)
            $this.Logger.LogTrace("$($propertyName)=$($propertyValue)")
        }
        $this.Logger.LogTrace("---END ITEM DATA---")
    }
}

Function New-CsvProcessorInstance($logger, $processItemFunction)
{
  return [CsvProcessor]::new($logger, $processItemFunction)
}