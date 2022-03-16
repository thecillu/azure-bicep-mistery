resource mySimpleAppServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: 'mysimpleappserviceplan'
  location: resourceGroup().location
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 1
    family: 'S'
    capacity: 3
  }
}

resource mySimpleStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'mysimplestorageaccount'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}


var simpleStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${mySimpleStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(mySimpleStorageAccount.id, mySimpleStorageAccount.apiVersion).keys[0].value}'

resource mySimpleFunctionApp 'Microsoft.Web/sites@2020-12-01' = {
  name: 'mysimplefunctionapp'
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    httpsOnly: 'true'
    serverFarmId: mySimpleAppServicePlan.id
    siteConfig: {
      alwaysOn: true
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
dependsOn: [
    mySimpleAppServicePlan
    mySimpleStorageAccount
  ]
}
resource mySimpleFunctionAppConfig 'Microsoft.Web/sites/config@2020-12-01' = {
  name: 'mysimplefunctionapp/appsettings'
  properties: {
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    AzureWebJobsStorage: simpleStorageConnectionString
  }
dependsOn: [
    mySimpleFunctionApp
  ]
}
