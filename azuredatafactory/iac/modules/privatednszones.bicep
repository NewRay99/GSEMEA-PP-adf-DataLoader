param vnetId string
param autoVmRegistration bool = false
param tags object

param adfsuffix string = 'datafactory.azure.net'
param adfprivatednsname string = 'privatelink.${adfsuffix}'

resource privateDnsZone_adf 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: adfprivatednsname
  location: 'global'
}

resource virtualNetworkLink_adf 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZone_adf.name}/${privateDnsZone_adf.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: autoVmRegistration
    virtualNetwork: {
      id: vnetId
    }
  }
  tags: tags
}

output outadfdnsId string = privateDnsZone_adf.id
