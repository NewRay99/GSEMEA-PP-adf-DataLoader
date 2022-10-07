param location string = resourceGroup().location

resource ammpn01iacsa 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: 'ammpn01iacsa'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

//output keys object = ammpn01iacsa.listKeys()
