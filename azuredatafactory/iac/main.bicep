//GLOBAL VARIABLES
targetScope = 'resourceGroup'
param projectName string = 'S161-ESFA-Adopt'
param repositoryName string = 'odin-ODP-adf'
param subscriptionId string = '81703de1-ec12-47e5-91f8-ef521199196e'

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
//resourcegroupname = s161d01-rg-ODP

var deploymentSettings = {
  Dev: {
    resourcePrefix: 's161d01'
    CoreRG: 's161d01-core'
    vNet: 's161d01-core-vn-01'
    subNet: 's161d01-core-sn-03'
    opsRG: 's161d01-rg-ops-core'
    coreDSKVName: 's161d01-kv-ops'
    dataFactoryName: 's161d01-adf-platform'
    userAssignedIdentities: 's161d01-uami-adf-platform'
  }
  DevTest: {
    resourcePrefix: 's161d02'
    CoreRG: 's161d02-core'
    vNet: 's161d02-core-vn-01'
    subNet: 's161d02-core-sn-02'
    opsRG: 's161d02-rg-ops-core'
    coreDSKVName: 's161d02-kv-ops'
    dataFactoryName: 's161d02-adf-platform'
    userAssignedIdentities: 's161d02-uami-adf-platform'
  }
  Test: {
    resourcePrefix: 's161t01'
    CoreRG: 's161t01-core'
    vNet: 's161t01-core-vn-01'
    subNet: 's161t01-core-sn-01'
    opsRG: 's161t01-rg-ops-core'
    coreDSKVName: 's161t01-kv-ops'
    dataFactoryName: 's161t01-adf-platform'
    userAssignedIdentities: 's161t01-uami-adf-platform'
  }
  Prod: {
    resourcePrefix: 's161p01'
    CoreRG: 's161p01-core'
    vNet: 's161p01-core-vn-01'
    subNet: 's161p01-core-sn-01'
    opsRG: 's161p01-rg-ops-core'
    coreDSKVName: 's161p01-kv-ops'
    dataFactoryName: 's161p01-adf-platform'
    userAssignedIdentities: 's161p01-uami-adf-platform'
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

//resourcePrefix = s161d01

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
