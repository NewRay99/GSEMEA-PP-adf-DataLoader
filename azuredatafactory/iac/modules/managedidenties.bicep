param location string = resourceGroup().location
param userAssignedIdentities string
param tags object

resource MI_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentities
  location: location
  tags: tags
}

output userAssignedId string = MI_resource.id
