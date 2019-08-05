
param
(
    [Parameter(Mandatory=$true, HelpMessage="The name of the DevTest Lab to update")]
    [string] $DevTestLabName,

    [Parameter(Mandatory=$true, HelpMessage="The array of Marketplace Image names to enable")]
    [Array] $ImagesToAdd
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
    $existingPolicy = (Get-AzResource -ResourceType 'Microsoft.DevTestLab/labs/policySets/policies' -ResourceName $labResourceName -ResourceGroupName $lab.ResourceGroupName -ApiVersion 2016-05-15) | Where-Object {$_.Name -eq 'GalleryImage'}
    if($existingPolicy)
    {
        $existingImages = [Array] (ConvertFrom-Json $existingPolicy.Properties.threshold)
        $savePolicyChanges = $false
    }
    else
    {
        $existingImages =  @()
        $savePolicyChanges = $true
    }

    if($existingPolicy.Properties.threshold -eq '[]')
    {
        Write-Output "Skipping $($lab.Name) because it currently allows all marketplace images"
        return
    }

    $allAvailableImages = Get-AzResource -ResourceType Microsoft.DevTestLab/labs/galleryImages -ResourceName $lab.Name -ResourceGroupName $lab.ResourceGroupName -ApiVersion 2017-04-26-preview
    $finalImages = $existingImages

    # loop through the requested images and add them to the finalImages list if they arent already there
    foreach($image in $ImagesToAdd)
    {
        $imageObject = $allAvailableImages | Where-Object {$_.Name -eq $image}
        
        if(!$imageObject)
        {
            throw "Image $image is not available in the lab"
        }

        $addImage = $true
        $parsedAvailableImage = $imageObject.Properties.imageReference

        foreach($finalImage in $finalImages)
        {
            # determine whether or not the requested image is already allowed in this lab
            $parsedFinalImg = ConvertFrom-Json $finalImage

            if($parsedFinalImg.offer -eq $parsedAvailableImage.offer -and $parsedFinalImg.publisher -eq $parsedAvailableImage.publisher -and $parsedFinalImg.sku -eq $parsedAvailableImage.sku -and $parsedFinalImg.osType -eq $parsedAvailableImage.osType -and $parsedFinalImg.version -eq $parsedAvailableImage.version)
            {
                $addImage = $false
                break
            }
        }

        if($addImage)
        {
            Write-Output "  Adding image $image to the lab"
            $finalImages += ConvertTo-Json $parsedAvailableImage -Compress
            $savePolicyChanges = $true
        }
    }

    if(!$savePolicyChanges)
    {
        Write-Output "No policy changes required for allowed Marketplace Images in lab $($lab.Name)"
    }

    return @{
        existingPolicy = $existingPolicy
        savePolicyChanges = $savePolicyChanges
        finalImages = $finalImages
    }
}

function Set-PolicyChanges ($lab, $policyChanges)
{
    if($policyChanges.savePolicyChanges)
    {
        $thresholdValue = '["'
        for($i = 0; $i -lt $policyChanges.finalImages.Length; $i++)
        {
            $value = $policyChanges.finalImages[$i]
            if($i -ne 0)
            {
                $thresholdValue = $thresholdValue + '","'
            }

            $thresholdValue = $thresholdValue + $value.Replace('"', '\"')
        }
        $thresholdValue = $thresholdValue + '"]'

        $policyObj = @{
            status = 'Enabled'
            factName = 'GalleryImage'
            threshold = $thresholdValue
            evaluatorType = 'AllowedValuesPolicy'
        }

        $resourceType = "Microsoft.DevTestLab/labs/policySets/policies/galleryimage"
        if($policyChanges.existingPolicy)
        {
            Write-Output "Updating $($lab.Name) Marketplace Images policy"
            Set-AzResource -ResourceType $resourceType -ResourceName $labResourceName -ResourceGroupName $lab.ResourceGroupName -ApiVersion 2017-04-26-preview -Properties $policyObj -Force
        }
        else
        {
            Write-Output "Creating $($lab.Name) Marketplace Images policy"
            New-AzResource -ResourceType $resourceType -ResourceName $labResourceName -ResourceGroupName $lab.ResourceGroupName -ApiVersion 2017-04-26-preview -Properties $policyObj -Force
        }
    }
}

$lab = Get-Lab
$policyChanges = Get-PolicyChanges $lab
Set-PolicyChanges $lab $policyChanges
