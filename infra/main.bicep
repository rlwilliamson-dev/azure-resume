@description('Base name used for Cosmos DB resources. Must be globally unique.')
param cosmosAccountName string = 'cosmos-resume-${uniqueString(resourceGroup().id)}'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Name of the Cosmos SQL database.')
param databaseName string = 'AzureResume'

@description('Name of the Cosmos SQL container.')
param containerName string = 'Counter'

@description('Tags applied to all resources.')
param tags object = {
  project: 'azure-cloud-resume'
  managedBy: 'bicep'
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [
      { name: 'EnableServerless' }
    ]
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    enableAutomaticFailover: true
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: 'Tls12'
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmos
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [ '/id' ]
        kind: 'Hash'
        version: 2
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          { path: '/*' }
        ]
        excludedPaths: [
          { path: '/"_etag"/?' }
        ]
      }
    }
  }
}

@description('Cosmos DB account name')
output cosmosAccountName string = cosmos.name

@description('Cosmos DB endpoint')
output cosmosEndpoint string = cosmos.properties.documentEndpoint
