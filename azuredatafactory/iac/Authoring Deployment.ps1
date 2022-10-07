# variables
.'.\00 variables.ps1'

az deployment group create --resource-group $RG --template-file .\datafactory.bicep --parameters environment=dev

az deployment group create --resource-group 'rg-devt-gsemeapp' --template-file .\datafactory.bicep --parameters environment=dev

az deployment group create --resource-group 'rg-devt-gsemeapp' --template-file .\arm-storage-account.bicep 


az deployment group create --resource-group 'rg-devt-gsemeapp' --template-file .\main.bicep --parameters environment=dev



az deployment group create --resource-group 'devt-core' --template-file .\subnet.bicep --parameters vnetName=devt-core-vn-01 privateLinkSubnetName=devt-core-sn-03 addressPrefix=10.183.61.32/28 --query 'properties.outputs.addressPrefix.value' -o tsv

$names = az datafactory trigger list --factory-name "adf-stage-gsemeapp" --query "[?properties.runtimeState=='Started'].name" -o tsv --only-show-errors
foreach ($name in $names) {
    az datafactory trigger stop --factory-name "adf-stage-gsemeapp" --resource-group "stage-rg-odp" --name $name --only-show-errors
}