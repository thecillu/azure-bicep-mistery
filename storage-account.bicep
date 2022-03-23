param storageAccountName string
param storageAccountEnableFirewall bool
param virtualNetworkSubnetIds array

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: storageAccountEnableFirewall ? 'Deny' : 'Allow'
      virtualNetworkRules: [for i in range(0, length(virtualNetworkSubnetIds)): {
        id: virtualNetworkSubnetIds[i]
      }]
    }
  }
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'

output storageConnectionString string = storageConnectionString
