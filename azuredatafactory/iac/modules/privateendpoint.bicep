param subscriptionId string
param CoreRG string
param location string = resourceGroup().location
param tags object

param vNet string
param subNet string
param subnetId string = '/subscriptions/${subscriptionId}/resourceGroups/${CoreRG}/providers/Microsoft.Network/virtualNetworks/${vNet}/subnets/${subNet}'

param privateLinkServiceId string
param privateDnsZoneId string
param privateDNSZoneGroupName string
param groupIds array

param endpointname string
param linkname string

resource PE_resource 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: endpointname
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: linkname
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
  tags: tags
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${PE_resource.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDNSZoneGroupName
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output PEId string = PE_resource.id
