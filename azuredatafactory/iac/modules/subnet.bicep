param vnetName string
param privateLinkSubnetName string
param CoreRG string = 's161d01-core'
param addressPrefix string

resource existingVNET 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  scope: resourceGroup(CoreRG)
  name: vnetName
}

resource subnet_resource 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  //parent: existingVNET
  name: '${vnetName}/${privateLinkSubnetName}'
  properties: {
    privateEndpointNetworkPolicies: 'Disabled'
    addressPrefix: addressPrefix
  }
  // dependsOn: [
  //   existingSubnet
  // ]
}

output addressPrefix string = subnet_resource.properties.addressPrefix
//az network vnet subnet update --disable-private-endpoint-network-policies true --name s161t01-core-sn-01 --resource-group s161t01-core --vnet-name s161t01-core-vn-01
