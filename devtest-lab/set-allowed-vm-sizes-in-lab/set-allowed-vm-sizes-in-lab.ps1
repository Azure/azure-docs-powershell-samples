param
(
    [Parameter(Mandatory=$true, HelpMessage="The name of the DevTest Lab to update")]
    [string] $DevTestLabName,

    [Parameter(Mandatory=$true, HelpMessage="The array of VM Sizes to be added")]
    [Array] $SizesToAdd
)

function Get-Lab
{
    $lab = Find-AzResource -ResourceType 'Microsoft.DevTestLab/labs' -ResourceNameEquals $DevTestLabName

    if(!$lab)
    {
        throw "Lab named $DevTestLabName was not found"
    }
    
    return $lab
}

function Get-PolicyChanges ($lab)
{
    #start by finding the existing policy
    $script:labResourceName = $lab.Name + '/default'
    $existingPolicy = (Get-AzResource -ResourceType 'Microsoft.DevTestLab/labs/policySets/policies' -ResourceName $labResourceName -ResourceGroupName $lab.ResourceGroupName -ApiVersion 2016-05-15) | Where-Object {$_.Name -eq 'AllowedVmSizesInLab'}
    if($existingPolicy)
    {
        $existingSizes = $existingPolicy.Properties.threshold
        $savePolicyChanges = $false
    }
    else
    {
        $existingSizes = ''
        $savePolicyChanges = $true
    }

    if($existingPolicy.Properties.threshold -eq '[]')
    {
        Write-Output "Skipping $($lab.Name) because it currently allows all sizes"
        return
    }

    # Make a list of all the sizes. It needs all their current sizes as well as any from our list that arent already there
    $finalVmSizes = $existingSizes.Replace('[', '').Replace(']', '').Split(',',[System.StringSplitOptions]::RemoveEmptyEntries)

    foreach($vmSize in $SizesToAdd)
    {
        $quotedSize = '"' + $vmSize + '"'

        if(!$finalVmSizes.Contains($quotedSize))
        {
            $finalVmSizes += $quotedSize
            $savePolicyChanges = $true
        }
    }

    if(!$savePolicyChanges)
    {
        Write-Output "No policy changes required for VMSize in lab $($lab.Name)"
    }

    return @{
        existingPolicy = $existingPolicy
        savePolicyChanges = $savePolicyChanges
        finalVmSizes = $finalVmSizes
    }
}

function Set-PolicyChanges ($lab, $policyChanges)
{
    if($policyChanges.savePolicyChanges)
    {
        $thresholdValue = ('[' + [String]::Join(',', $policyChanges.finalVmSizes) + ']')

        $policyObj = @{
            subscriptionId = $lab.SubscriptionId
            status = 'Enabled'
            factName = 'LabVmSize'
            resourceGroupName = $lab.ResourceGroupName
            labName = $lab.Name
            policySetName = 'default'
            name = $lab.Name + '/default/allowedvmsizesinlab'
            threshold = $thresholdValue
            evaluatorType = 'AllowedValuesPolicy'
        }

        $resourceType = "Microsoft.DevTestLab/labs/policySets/policies/AllowedVmSizesInLab"
        if($policyChanges.existingPolicy)
        {
            Write-Output "Updating $($lab.Name) VM Size policy"
            Set-AzResource -ResourceType $resourceType -ResourceName $labResourceName -ResourceGroupName $lab.ResourceGroupName -ApiVersion 2016-05-15 -Properties $policyObj -Force
        }
        else
        {
            Write-Output "Creating $($lab.Name) VM Size policy"
            New-AzResource -ResourceType $resourceType -ResourceName $labResourceName -ResourceGroupName $lab.ResourceGroupName -ApiVersion 2016-05-15 -Properties $policyObj -Force
        }
    }
}

$lab = Get-Lab
$policyChanges = Get-PolicyChanges $lab
Set-PolicyChanges $lab $policyChanges
