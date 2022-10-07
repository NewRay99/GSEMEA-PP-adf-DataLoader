# variables
.'.\00 variables.ps1'

az deployment group create --resource-group $RG --template-file .\datafactory.bicep --parameters environment=dev

az deployment group create --resource-group 's161d01-rg-odp' --template-file .\datafactory.bicep --parameters environment=dev

az deployment group create --resource-group 's161d01-rg-odp' --template-file .\arm-storage-account.bicep 


az deployment group create --resource-group 's161d01-rg-odp' --template-file .\main.bicep --parameters environment=dev



az deployment group create --resource-group 's161d01-core' --template-file .\subnet.bicep --parameters vnetName=s161d01-core-vn-01 privateLinkSubnetName=s161d01-core-sn-03 addressPrefix=10.183.61.32/28 --query 'properties.outputs.addressPrefix.value' -o tsv

$names = az datafactory trigger list --factory-name "s161t01-adf-platform" --query "[?properties.runtimeState=='Started'].name" -o tsv --only-show-errors
foreach ($name in $names) {
    az datafactory trigger stop --factory-name "s161t01-adf-platform" --resource-group "s161t01-rg-odp" --name $name --only-show-errors
}