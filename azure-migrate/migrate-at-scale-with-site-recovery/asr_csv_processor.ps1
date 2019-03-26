class CsvProcessor
{
    [psobject]$Logger
    [psobject]$ProcessItemFunction

    CsvProcessor($logger, $processItemFunction)
    {
        $this.Logger = $logger
        $this.ProcessItemFunction = $processItemFunction
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
        $CsvOutputFileName = [string]::Concat("out.", $scriptName, ".", $csvFileName, ".", $this.FormatDate($startDate), ".csv")
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

        $protectedItemStatusArray = New-Object System.Collections.Generic.List[System.Object]
        foreach ($csvItem in $csvObj)
        {
            $reportItemInfo = [PSCustomObject]@{
                Machine = $($csvItem.SOURCE_MACHINE_NAME)
                Exception = $null
            }
            try {
                $this.EnsureSubscription($csvItem.VAULT_SUBSCRIPTION_ID)
                $this.PrintSettings($csvItem)
            
                $this.ProcessItemFunction.Invoke($this, $csvItem, $reportItemInfo)
            } catch {
                $this.Logger.LogError("Exception processing item")
                $exceptionMessage = $_ | Out-String
                $this.Logger.LogError($exceptionMessage)

                $reportItemInfo.Exception = "EXCEPTION PROCESSING ITEM"
            }
            $protectedItemStatusArray.Add($reportItemInfo)
        }
        $this.Logger.LogTrace("Creating Csv reporting output '$($CsvOutputFilePath)'")
        $protectedItemStatusArray.ToArray() | Export-Csv -LiteralPath $CsvOutputFilePath -Delimiter ',' -NoTypeInformation

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

Function New-CsvProcessorInstance($Logger, $ProcessItemFunction)
{
  return [CsvProcessor]::new($logger, $processItemFunction)
}

