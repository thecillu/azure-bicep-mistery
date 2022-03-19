resource mySimpleAppServicePlan 'Microsoft.Web/serverfarms@2020-12-01' existing = {
  name: 'mysimpleappserviceplan'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: 'my-existing-vnet'
}

resource virtualNetworkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: 'my-existing-subnet'
  parent: virtualNetwork
}

resource myComplexStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'mycomplexstorageaccount'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: virtualNetworkSubnet.id
        }
      ]
    }
  }
}

var simpleStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${myComplexStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(myComplexStorageAccount.id, myComplexStorageAccount.apiVersion).keys[0].value}'

resource myComplexFunctionApp 'Microsoft.Web/sites@2020-12-01' = {
  name: 'mycomplexfunctionapp'
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: mySimpleAppServicePlan.id
    siteConfig: {
      alwaysOn: true
      vnetRouteAllEnabled: true
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    mySimpleAppServicePlan
    myComplexStorageAccount
  ]
}
resource myComplexFunctionAppConfig 'Microsoft.Web/sites/config@2020-12-01' = {
  name: 'mycomplexfunctionapp/appsettings'
  properties: {
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    AzureWebJobsStorage: simpleStorageConnectionString
  }
  dependsOn: [
    myComplexFunctionApp
  ]
}

resource networkConfig 'Microsoft.Web/sites/networkConfig@2021-01-15' = {
  parent: myComplexFunctionApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: resourceId(resourceGroup().id, 'Microsoft.Network/virtualNetworks/subnets', 'my-existing-vnet', 'my-existing-subnet')
  }

  dependsOn: [
    myComplexFunctionApp
  ]
}

resource myComplexFunctionAppWebConfig 'Microsoft.Web/sites/config@2020-12-01' = {
  name: 'mycomplexfunctionapp/web'
  properties: {
    ipSecurityRestrictions: {
      ipAddress: 'Any'
      action: 'Deny'
      priority: 100
      name: 'Deny All'
      description: 'Deny All'
    }
  }
  dependsOn: [
    myComplexFunctionApp
  ]
}
