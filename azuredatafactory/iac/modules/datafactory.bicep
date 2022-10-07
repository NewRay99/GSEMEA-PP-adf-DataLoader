param location string = resourceGroup().location
param version string = 'V2'
param dataFactoryName string
param userAssignedId string
param repositoryName string = 'infrared-ODP-adf-iac'
param tags object
param environment string = 'Dev'

@allowed([
  'FactoryVSTSConfiguration'
  'FactoryGitHubConfiguration'
])
param repositoryType string = 'FactoryVSTSConfiguration'
param projectName string = 'GSEMEA-PP-adf-DataLoader'
param accountName string = 'dfe-ssp'
param collaborationBranch string = 'main'
param rootFolder string = '/azuredatafactory/src'

var azDevopsRepoConfiguration = {
  accountName: accountName
  repositoryName: repositoryName
  collaborationBranch: collaborationBranch
  rootFolder: rootFolder
  type: repositoryType
  projectName: projectName
}

var gitHubRepoConfiguration = {
  accountName: accountName
  repositoryName: repositoryName
  collaborationBranch: collaborationBranch
  rootFolder: rootFolder
  type: repositoryType
}

var properties = {
  repoConfiguration: (repositoryType == 'FactoryVSTSConfiguration') ? azDevopsRepoConfiguration : gitHubRepoConfiguration

  publicNetworkAccess: 'Disabled'
}

resource dataFactoryName_resource 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedId}': {}
    }
  }
  properties: (environment == 'Dev') ? properties : {}
}

resource name_default 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = if (version == 'V2') {
  parent: dataFactoryName_resource
  name: 'default'
  properties: {}
}

resource name_AutoResolveIntegrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = if (version == 'V2') {
  parent: dataFactoryName_resource
  name: 'AutoResolveIntegrationRuntime'
  properties: {
    type: 'Managed'
    managedVirtualNetwork: {
      referenceName: 'default'
      type: 'ManagedVirtualNetworkReference'
    }
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
      }
    }
  }
  dependsOn: [
    name_default
  ]
}

output outadfId string = dataFactoryName_resource.id
