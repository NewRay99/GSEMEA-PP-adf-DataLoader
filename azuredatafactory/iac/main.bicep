//GLOBAL VARIABLES
targetScope = 'resourceGroup'
param projectName string = 'GSEMEA-PP-adf-DataLoader'
param repositoryName string = 'odin-ODP-adf'
param subscriptionId string = 'abc596af-81dc-4cac-87d1-d89cd6c6e10e'

// param vNet string
// param subNet string
//param resourcePrefix string
//param coreDSKVName string
//param coreDSRGName string

@allowed([
  'Dev'
  'DevTest'
  'Test'
  'Prod'
])
param environment string = 'Dev'

//LOCAL VARIABLES
param location string = resourceGroup().location
param resourcegroupname string = resourceGroup().name
//resourcegroupname = rg-devt-gsemeapp

var deploymentSettings = {
  Dev: {
    resourcePrefix: 'devt'
    CoreRG: 'devt-core'
    vNet: 'devt-core-vn-01'
    subNet: 'devt-core-sn-03'
    opsRG: 'devt-rg-ops-core'
    coreDSKVName: 'devt-core-kv-01'
    dataFactoryName: 'adf-devt-gsemeapp'
    userAssignedIdentities: 'devt-uami-adf-platform'
  }
  DevTest: {
    resourcePrefix: 'devt'
    CoreRG: 'devt-core'
    vNet: 'devt-core-vn-01'
    subNet: 'devt-core-sn-02'
    opsRG: 'devt-rg-ops-core'
    coreDSKVName: 'devt-core-kv-01'
    dataFactoryName: 'adf-devt-gsemeapp'
    userAssignedIdentities: 'devt-uami-adf-platform'
  }
  Test: {
    resourcePrefix: 'stage'
    CoreRG: 'stage-core'
    vNet: 'stage-core-vn-01'
    subNet: 'stage-core-sn-01'
    opsRG: 'stage-rg-ops-core'
    coreDSKVName: 'stage-kv-ops'
    dataFactoryName: 'adf-stage-gsemeapp'
    userAssignedIdentities: 'stage-uami-adf-platform'
  }
  Prod: {
    resourcePrefix: 'prod'
    CoreRG: 'prod-core'
    vNet: 'prod-core-vn-01'
    subNet: 'prod-core-sn-01'
    opsRG: 'prod-rg-ops-core'
    coreDSKVName: 'prod-kv-ops'
    dataFactoryName: 'adf-prod-gsemeapp'
    userAssignedIdentities: 'prod-uami-adf-platform'
  }
}

var tags = {
  Environment: environment
  Portfolio: 'Education and Skills Funding Agency'
  'Service Line': 'Data Operations'
  Service: 'Business Intelligence'
  Product: 'ESFA Adopt Programme'
  'Service Offering': 'ESFA Adopt Programme'
}

//resourcePrefix = devt

resource kvsecret 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: deploymentSettings[environment].coreDSKVName
  scope: resourceGroup(subscriptionId, deploymentSettings[environment].opsRG)
}

module MI './modules/managedidenties.bicep' = {
  //scope: resourceGroup('${resourcegroupname}')
  name: deploymentSettings[environment].userAssignedIdentities
  params: {
    userAssignedIdentities: deploymentSettings[environment].userAssignedIdentities
    location: location
    tags: tags
  }
}

//build ADF
module adf './modules/datafactory.bicep' = {
  scope: resourceGroup(resourcegroupname)
  name: 'ADF-deploy'
  params: {
    repositoryName: repositoryName
    projectName: projectName
    dataFactoryName: deploymentSettings[environment].dataFactoryName
    location: location
    environment: environment
    userAssignedId: MI.outputs.userAssignedId
    tags: tags
  }
  dependsOn: [
    MI
  ]
}

//Skip Azure SQL as this should alreeady be created

//Skip Storage Account

//Skip Private Endpoint ADLS

// add privednszones for adf
resource corevnetid 'Microsoft.Network/virtualNetworks@2020-07-01' existing = {
  name: deploymentSettings[environment].vNet
  scope: resourceGroup(deploymentSettings[environment].CoreRG)
}

////Skip Private DNS Zones
// module adfprivatednszones './modules/privatednszones.bicep' = {
//   name: 'adf-privatednszones'
//   scope: resourceGroup(deploymentSettings[environment].CoreRG) //point to the Project RG
//   params: {
//     vnetId: corevnetid.id
//     tags: tags
//   }
// }

//subnet edit policy

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  scope: resourceGroup(deploymentSettings[environment].CoreRG)
  name: '${deploymentSettings[environment].vNet}/${deploymentSettings[environment].subNet}'
}

module adfsubnet './modules/subnet.bicep' = {
  name: 'adf-subnet-edit-policy'
  scope: resourceGroup(deploymentSettings[environment].CoreRG) //point to the core RG
  params: {
    vnetName: deploymentSettings[environment].vNet
    privateLinkSubnetName: deploymentSettings[environment].subNet
    addressPrefix: existingSubnet.properties.addressPrefix
  }
}

// //Private Endpoint ADF

// var adfendpointname = '${deploymentSettings[environment].resourcePrefix}-pep-${deploymentSettings[environment].dataFactoryName}-vnet'
// var adflinkname = '${deploymentSettings[environment].resourcePrefix}-pvl-${deploymentSettings[environment].dataFactoryName}-vnet'

// param adfgroupIds array = [
//   'dataFactory'
// ]
// param adfprivateDNSZoneGroupName string = 'privatelink-datafactory-azure-net'

// module adfpep './modules/privateendpoint.bicep' = {
//   scope: resourceGroup(resourcegroupname)
//   name: 'adf-pep'
//   params: {
//     subscriptionId: subscriptionId
//     CoreRG: deploymentSettings[environment].CoreRG
//     location: location
//     privateLinkServiceId: adf.outputs.outadfId
//     privateDnsZoneId: adfprivatednszones.outputs.outadfdnsId
//     vNet: deploymentSettings[environment].vNet
//     subNet: deploymentSettings[environment].subNet
//     endpointname: adfendpointname
//     linkname: adflinkname
//     privateDNSZoneGroupName: adfprivateDNSZoneGroupName
//     groupIds: adfgroupIds
//     tags: tags
//   }
//   dependsOn: [
//     adf
//     adfsubnet
//     adfprivatednszones
//   ]
// }
