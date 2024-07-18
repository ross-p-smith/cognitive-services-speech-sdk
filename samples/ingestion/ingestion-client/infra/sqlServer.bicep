param DatabaseName string
param PrimaryBlobEndpoint string
@secure()
param StorageAccountResourceId string
param SqlServerName string
param SqlAdministratorLogin string
@secure()
param SqlAdministratorLoginPassword string

resource SqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: SqlServerName
  location: resourceGroup().location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: SqlAdministratorLogin
    administratorLoginPassword: SqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource SqlServerName_Database 'Microsoft.Sql/servers/databases@2015-01-01' = {
  parent: SqlServer
  name: DatabaseName
  location: resourceGroup().location
  tags: {
    displayName: 'Database'
  }
  properties: {
    edition: 'Basic'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    requestedServiceObjectiveName: 'Basic'
  }
}

resource SqlServerName_DatabaseName_current 'Microsoft.Sql/servers/databases/transparentDataEncryption@2014-04-01-preview' = {
  parent: SqlServerName_Database
  name: 'current'
  location: resourceGroup().location
  properties: {
    status: 'Enabled'
  }
}

resource SqlServerName_AllowAllMicrosoftAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01' = {
  parent: SqlServer
  name: 'AllowAllMicrosoftAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource SqlServerName_DefaultAuditingSettings 'Microsoft.Sql/servers/auditingSettings@2017-03-01-preview' = {
  parent: SqlServer
  name: 'DefaultAuditingSettings'
  properties: {
    state: 'Enabled'
    storageEndpoint: PrimaryBlobEndpoint
    storageAccountAccessKey: listKeys(StorageAccountResourceId, '2018-03-01-preview').keys[0].value
    storageAccountSubscriptionId: subscription().subscriptionId
    auditActionsAndGroups: null
    isStorageSecondaryKeyInUse: false
  }
}
