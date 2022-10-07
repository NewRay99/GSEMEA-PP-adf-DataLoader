$artifactStagingDirectory = 'd:\a\1\drop' #$args[0] # overwriting: $(Build.ArtifactStagingDirectory)
$depEnv = $args[1]
$rgName = $args[2]
$depEnvAbbrv = $args[3]

# For tool and parameter help see: https://github.com/SQLPlayer/azure.datafactory.tools

# Set config and deployment options
$rootFolder = $artifactStagingDirectory
$deploymentConfig = $artifactStagingDirectory + "\deployment\config-$depEnv.csv"
$opt = New-AdfPublishOption
#$opt.Includes.Add("linkedService", "")
#$opt = New-AdfPublishOption -FilterFilePath "$artifactStagingDirectory\deployment\rules.txt"
$opt.StopStartTriggers = $true
$opt.DeleteNotInSource = $true

# Get the data factory name and location (the Name and Location properties from the data factory definition file)
$jsonFactory = $artifactStagingDirectory + "\factory\"
Get-ChildItem $jsonFactory *.json | Select-Object -First 1 | Foreach-Object {
    $jsonFile = $jsonFactory + $_.Name
    #Get-Content $jsonFile
    $JSON = Get-Content $jsonFile | Out-String | ConvertFrom-Json
    $adfName = $JSON[0].name 
    $location = $JSON[0].location
}
$dataFactoryName = $adfName -replace "-dev-", $depEnvAbbrv
Write-Host "DataFactoryName: $dataFactoryName"

# Stop any ADF triggers
#Write-Host "${dataFactoryName}: Stopping TR_DI_Agent trigger ..."
#Stop-AzDataFactoryV2Trigger -ResourceGroupName $rgName -DataFactoryName $dataFactoryName -TriggerName "TR_DI_Agent" -Force

# Publish the ADF
Publish-AdfV2FromJson `
    -RootFolder "$rootFolder" `
    -ResourceGroupName "$rgName" `
    -DataFactoryName "$dataFactoryName" `
    -Location "$location" `
    -Stage $depEnv `
    -Option $opt
Write-Host "Published ADF"

# Start any ADF triggers
#Write-Host "${dataFactoryName}: Starting TR_DI_Agent trigger ..."
#Start-AzDataFactoryV2Trigger -ResourceGroupName $rgName -DataFactoryName $dataFactoryName -TriggerName "TR_DI_Agent" -Force

# Set access to the Key Vault for the Data Factory (needed for the KV linked service in the ADF)
Write-Host "Setting Managed Identity on key vault for data factory"
$content = (Get-Content -path $deploymentConfig -Raw) -split "," | Where-Object  { $_ -like '*.vault.azure.net*' }
$keyVaultLs = Get-AzKeyVault 

$kvMatches = $keyVaultLs | Where-Object  {$content  -match  $_.VaultName }
ForEach  ($kvMatch in $kvMatches)
{
    $kvName = $kvMatch.VaultName
    $kvResourceGroup = $kvMatch.ResourceGroupName
    $adfIdentity = (Get-AzDataFactoryV2 -ResourceGroupName $rgName -Name $dataFactoryName).Identity
    $adfIdentityId = $adfIdentity.PrincipalId
    Write-host "KeyVault Name: $kvName KeyVault ResouceGroup: $kvResourceGroup ADF Identity: $adfIdentity Id: $adfIdentityId"
    Set-AzKeyVaultAccessPolicy `
        -VaultName $kvName `
        -ObjectId $adfIdentityId `
        -ResourceGroupName $kvResourceGroup `
        -PermissionsToSecrets set,delete,get `
        -BypassObjectIdValidation
} 
Write-Host "Managed Identity permissions created"
