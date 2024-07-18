@description('The name of the storage account. It must be unique across all existing storage account names in Azure, between 3 and 24 characters long, and can contain only lowercase letters and numbers.')
param StorageAccount string

@allowed([
  'ar-BH | Arabic (Bahrain)'
  'ar-EG | Arabic (Egypt)'
  'ar-SY | Arabic (Syria)'
  'ca-ES | Catalan'
  'da-DK | Danish (Denmark)'
  'de-DE | German (Germany)'
  'en-AU | English (Australia)'
  'en-CA | English (Canada)'
  'en-GB | English (United Kingdom)'
  'en-IN | English (India)'
  'en-NZ | English (New Zealand)'
  'en-US | English (United States)'
  'es-ES | Spanish (Spain)'
  'es-MX | Spanish (Mexico)'
  'fi-FI | Finnish (Finland)'
  'fr-CA | French (Canada)'
  'fr-FR | French (France)'
  'gu-IN | Gujarati (Indian)'
  'hi-IN | Hindi (India)'
  'it-IT | Italian (Italy)'
  'ja-JP | Japanese (Japan)'
  'ko-KR | Korean (Korea)'
  'mr-IN | Marathi (India)'
  'nb-NO | Norwegian (Bokmål)'
  'nl-NL | Dutch (Netherlands)'
  'pl-PL | Polish (Poland)'
  'pt-BR | Portuguese (Brazil)'
  'pt-PT | Portuguese (Portugal)'
  'ru-RU | Russian (Russia)'
  'sv-SE | Swedish (Sweden)'
  'ta-IN | Tamil (India)'
  'te-IN | Telugu (India)'
  'th-TH | Thai (Thailand)'
  'tr-TR | Turkish (Turkey)'
  'zh-CN | Chinese (Mandarin, simplified)'
  'zh-HK | Chinese (Cantonese, Traditional)'
  'zh-TW | Chinese (Taiwanese Mandarin)'
])
param Locale string = 'en-US | English (United States)'

@description('The id of the custom model for transcription. If empty, the base model will be selected.')
param CustomModelId string = ''

@description('The key for the Azure Speech Services subscription.')
@secure()
param AzureSpeechServicesKey string

@description('The region the Azure speech services subscription is associated with.')
@allowed([
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westcentralus'
  'westus'
  'westus2'
  'canadacentral'
  'brazilsouth'
  'eastasia'
  'southeastasia'
  'australiaeast'
  'centralindia'
  'japaneast'
  'japanwest'
  'koreacentral'
  'northeurope'
  'westeurope'
  'francecentral'
  'uksouth'
  'usgovarizona'
  'usgovvirginia'
])
param AzureSpeechServicesRegion string = 'westus'

@description('Enter the address of your private endpoint here (e.g. https://mycustomendpoint.cognitiveservices.azure.com/) if you are connecting with a private endpoint')
param CustomEndpoint string = ''

@description('The time interval for the timer trigger in the StartTranscription function (https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer?tabs=python-v2%2Cisolated-process%2Cnodejs-v4&pivots=programming-language-csharp#ncrontab-expressions). The default value is every 2 minutes.')
param StartTranscriptionFunctionTimeInterval string = '0 */2 * * * *'

@description('The requested profanity filter mode.')
@allowed([
  'None'
  'Removed'
  'Tags'
  'Masked'
])
param ProfanityFilterMode string = 'None'

@description('The requested punctuation mode.')
@allowed([
  'None'
  'Dictated'
  'Automatic'
  'DictatedAndAutomatic'
])
param PunctuationMode string = 'DictatedAndAutomatic'

@description('A value indicating whether diarization (speaker separation) is requested.')
param AddDiarization bool = false

@description('A value indicating whether word level timestamps are requested.')
param AddWordLevelTimestamps bool = false

@description('The key for the Text Analytics subscription.')
@secure()
param TextAnalyticsKey string = ''

@description('The endpoint the Text Analytics subscription is associated with (format should be like https://{resourceName}.cognitiveservices.azure.com or https://{region}.api.cognitive.microsoft.com or similar). If empty, no text analysis will be performed.')
param TextAnalyticsEndpoint string = ''

@description('A value indicating whether sentiment analysis is requested (either per utterance or per audio). Will only be performed if a Text Analytics Key and Region is provided.')
@allowed([
  'None'
  'UtteranceLevel'
  'AudioLevel'
])
param SentimentAnalysis string = 'None'

@description('A value indicating whether personally identifiable information (PII) redaction is requested. Will only be performed if a Text Analytics Key and Region is provided.')
@allowed([
  'None'
  'UtteranceAndAudioLevel'
])
param PiiRedaction string = 'None'

@description('The administrator username of the SQL Server, which is used to gain insights of the audio with the provided PowerBI scripts. If it is left empty, no SQL server/database will be created.')
param SqlAdministratorLogin string = ''

@description('The administrator password of the SQL Server. If it is left empty, no SQL server/database will be created.')
@secure()
param SqlAdministratorLoginPassword string = ''

@description('Id that will be suffixed to all created resources to identify resources of a certain deployment. Leave as is to use timestamp as deployment id.')
param DeploymentId string = utcNow()

@description('The connection string for the Service Bus Queue where you want to receive the notification of completion of the transcription for each audio file. If left empty, no completion notification will be sent.')
@secure()
param CompletedServiceBusConnectionString string = ''

// Don't change the format for Version variable
var Version = 'v2.1.5'
var AudioInputContainer = 'audio-input'
var AudioProcessedContainer = 'audio-processed'
var ErrorFilesOutputContainer = 'audio-failed'
var JsonResultOutputContainer = 'json-result-output'
var HtmlResultOutputContainer = 'html-result-output'
var ErrorReportOutputContainer = 'error-report'
var ConsolidatedFilesOutputContainer = 'consolidated-files'
var CreateHtmlResultFile = 'false'
var CreateConsolidatedOutputFiles = 'false'
var TimerBasedExecution = true
var CreateAudioProcessedContainer = 'true'
var IsByosEnabledSubscription = 'false'
var MessagesPerFunctionExecution = '1000'
var FilesPerTranscriptionJob = '100'
var RetryLimit = '4'
var InitialPollingDelayInMinutes = '2'
var MaxPollingDelayInMinutes = '180'
var InstanceId = DeploymentId
var StorageAccountName = StorageAccount
var UseSqlDatabase = ((SqlAdministratorLogin != '') && (SqlAdministratorLoginPassword != ''))
var SqlServerName = 'sqlserver${toLower(InstanceId)}'
var DatabaseName = 'Database-${toLower(InstanceId)}'
var ServiceBusName = 'ServiceBus-${InstanceId}'
var AppInsightsName = 'AppInsights-${InstanceId}'
var KeyVaultName = 'KV-${InstanceId}'
var EventGridSystemTopicName = '${StorageAccountName}-${InstanceId}'
var StartTranscriptionFunctionName = take('StartTranscriptionFunction-${InstanceId}', 60)
var FetchTranscriptionFunctionName = take('FetchTranscriptionFunction-${InstanceId}', 60)
var AppServicePlanName = 'AppServicePlan-${InstanceId}'
var AzureSpeechServicesKeySecretName = 'AzureSpeechServicesKey'
var TextAnalyticsKeySecretName = 'TextAnalyticsKey'
var DatabaseConnectionStringSecretName = 'DatabaseConnectionString'
var PiiCategories = ''
var ConversationPiiCategories = ''
var ConversationPiiRedaction = 'None'
var ConversationPiiInferenceSource = 'text'
var ConversationSummarizationOptions = '{"Stratergy":{"Key":"Channel","Mapping":{"0":"Agent","1":"Customer"},"FallbackRole":"None"},"Aspects":["Issue","Resolution","ChapterTitle","Narrative"],"Enabled":false,"InputLengthLimit":125000}'
var IsAzureGovDeployment = ((AzureSpeechServicesRegion == 'usgovarizona') || (AzureSpeechServicesRegion == 'usgovvirginia'))
var AzureSpeechServicesEndpointUri = ((CustomEndpoint != '')
  ? CustomEndpoint
  : (IsAzureGovDeployment
      ? 'https://${AzureSpeechServicesRegion}.api.cognitive.microsoft.us/'
      : 'https://${AzureSpeechServicesRegion}.api.cognitive.microsoft.com/'))
var EndpointSuffix = (IsAzureGovDeployment ? 'core.usgovcloudapi.net' : 'core.windows.net')
var BinariesRoutePrefix = 'https://github.com/Azure-Samples/cognitive-services-speech-sdk/releases/download/ingestion-'
var StartTranscriptionByTimerBinary = '${BinariesRoutePrefix}${Version}/StartTranscriptionByTimer.zip'
var StartTranscriptionByServiceBusBinary = '${BinariesRoutePrefix}${Version}/StartTranscriptionByServiceBus.zip'
var FetchTranscriptionBinary = '${BinariesRoutePrefix}${Version}/FetchTranscription.zip'

resource AppInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: AppInsightsName
  location: resourceGroup().location
  tags: {
    applicationType: 'web'
    applicationName: 'TranscriptionInsights'
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource ServiceBus 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: ServiceBusName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    zoneRedundant: false
  }
}

resource KeyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: KeyVaultName
  location: resourceGroup().location
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    // accessPolicies: [
    //   {
    //     objectId: reference(AppServices.outputs.StartTranscriptionFunctionId, '2019-08-01', 'full').identity.principalId
    //     tenantId: reference(StartTranscriptionFunction.id, '2019-08-01', 'full').identity.tenantId
    //     permissions: {
    //       secrets: [
    //         'get'
    //         'list'
    //       ]
    //     }
    //   }
    //   {
    //     objectId: reference(FetchTranscriptionFunction.id, '2019-08-01', 'full').identity.principalId
    //     tenantId: reference(FetchTranscriptionFunction.id, '2019-08-01', 'full').identity.tenantId
    //     permissions: {
    //       secrets: [
    //         'get'
    //         'list'
    //       ]
    //     }
    //   }
    // ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource KeyVaultName_AzureSpeechServicesKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: KeyVault
  name: AzureSpeechServicesKeySecretName
  properties: {
    value: AzureSpeechServicesKey
  }
}

resource KeyVaultName_TextAnalyticsKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: KeyVault
  name: TextAnalyticsKeySecretName
  properties: {
    value: (empty(TextAnalyticsKey) ? 'NULL' : TextAnalyticsKey)
  }
}

resource KeyVaultName_DatabaseConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: KeyVault
  name: DatabaseConnectionStringSecretName
  properties: {
    value: (UseSqlDatabase
      ? 'Server=tcp:${reference(SqlServerName,'2014-04-01-preview').fullyQualifiedDomainName},1433;Initial Catalog=${DatabaseName};Persist Security Info=False;User ID=${SqlAdministratorLogin};Password=${SqlAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
      : 'NULL')
  }
  dependsOn: [
    SqlServer
  ]
}

module SqlServer 'sqlServer.bicep' = if (UseSqlDatabase) {
  name: 'SqlServerDeployment'
  params: {
    DatabaseName: DatabaseName
    PrimaryBlobEndpoint: StorageAccount_resource.outputs.primaryBlobEndpoint
    StorageAccountResourceId: StorageAccount_resource.outputs.resourceId
    SqlServerName: SqlServerName
    SqlAdministratorLogin: SqlAdministratorLogin
    SqlAdministratorLoginPassword: SqlAdministratorLoginPassword
  }
}

module AppServices 'appService.bicep' = {
  name: 'AppServicesDeployment'
  params: {
    AddDiarization: AddDiarization ? 'true' : 'false'
    AddWordLevelTimestamps: AddWordLevelTimestamps ? 'true' : 'false'
    AppInsightsName: AppInsightsName
    AppServicePlanName: AppServicePlanName
    AudioInputContainer: AudioInputContainer
    AudioProcessedContainer: AudioProcessedContainer
    AzureSpeechServicesKeySecretName: AzureSpeechServicesKeySecretName
    AzureSpeechServicesRegion: AzureSpeechServicesRegion
    AzureSpeechServicesEndpointUri: AzureSpeechServicesEndpointUri
    CompletedServiceBusConnectionString: CompletedServiceBusConnectionString
    CreateAudioProcessedContainer: CreateAudioProcessedContainer
    CreateConsolidatedOutputFiles: CreateConsolidatedOutputFiles
    CreateHtmlResultFile: CreateHtmlResultFile
    ConsolidatedFilesOutputContainer: ConsolidatedFilesOutputContainer
    ConversationPiiCategories: ConversationPiiCategories
    ConversationPiiInferenceSource: ConversationPiiInferenceSource
    ConversationPiiRedaction: ConversationPiiRedaction
    ConversationSummarizationOptions: ConversationSummarizationOptions
    CustomModelId: CustomModelId
    DatabaseConnectionStringSecretName: DatabaseConnectionStringSecretName
    EndpointSuffix: EndpointSuffix
    ErrorFilesOutputContainer: ErrorFilesOutputContainer
    ErrorReportOutputContainer: ErrorReportOutputContainer
    FilesPerTranscriptionJob: FilesPerTranscriptionJob
    FetchTranscriptionBinary: FetchTranscriptionBinary
    FetchTranscriptionFunctionName: FetchTranscriptionFunctionName
    HtmlResultOutputContainer: HtmlResultOutputContainer
    JsonResultOutputContainer: JsonResultOutputContainer
    InitialPollingDelayInMinutes: InitialPollingDelayInMinutes
    IsAzureGovDeployment: IsAzureGovDeployment ? 'true' : 'false'
    IsByosEnabledSubscription: IsByosEnabledSubscription
    KeyVaultName: KeyVaultName
    Locale: Locale
    MaxPollingDelayInMinutes: MaxPollingDelayInMinutes
    MessagesPerFunctionExecution: MessagesPerFunctionExecution
    PiiCategories: PiiCategories
    PiiRedaction: PiiRedaction
    ProfanityFilterMode: ProfanityFilterMode
    PunctuationMode: PunctuationMode
    RetryLimit: RetryLimit
    SentimentAnalysis: SentimentAnalysis
    ServiceBusName_fetch_transcription_queue_name: ServiceBusName_fetch_transcription_queue_FetchTranscription.name
    ServiceBusName_start_transcription_queue_name: ServiceBusName_start_transcription_queue_StartTranscription.name
    ServiceBusName_RootManageSharedAccessKeyName: ServiceBusName_RootManageSharedAccessKey.name
    StartTranscriptionByServiceBusBinary: StartTranscriptionByServiceBusBinary
    StartTranscriptionByTimerBinary: StartTranscriptionByTimerBinary
    StartTranscriptionFunctionTimeInterval: StartTranscriptionFunctionTimeInterval
    StorageAccountName: StorageAccountName
    StartTranscriptionFunctionName: StartTranscriptionFunctionName
    TextAnalyticsKeySecretName: TextAnalyticsKeySecretName
    TextAnalyticsEndpoint: TextAnalyticsEndpoint
    TimerBasedExecution: TimerBasedExecution
    UseSqlDatabase: UseSqlDatabase ? 'true' : 'false'
  }
  dependsOn: [
    AppInsights
    KeyVault
    KeyVaultName_AzureSpeechServicesKeySecret
    KeyVaultName_TextAnalyticsKeySecret
    StorageAccount_resource
  ]
}

module StorageAccount_resource 'br/public:avm/res/storage/storage-account:0.11.0' = {
  name: 'StorageAccountDeployment'
  params: {
    blobServices: {
      containers: {
        AudioInputContainer: {
          publicAccess: 'None'
        }
        JsonResultOutputContainer: {
          publicAccess: 'None'
        }
        ErrorReportOutputContainer: {
          publicAccess: 'None'
        }
        ErrorFilesOutputContainer: {
          publicAccess: 'None'
        }
        ConsolidatedFilesOutputContainer: {
          publicAccess: 'None'
        }
        AudioProcessedContainer: {
          publicAccess: 'None'
        }
        HtmlResultOutputContainer: {
          publicAccess: 'None'
        }
      }
      cors: {
        corsRules: []
      }
      deleteRetentionPolicy: {
        enabled: false
      }
    }
    name: StorageAccountName
    kind: 'StorageV2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    skuName: 'Standard_GRS'
  }
}

resource ServiceBusName_RootManageSharedAccessKey 'Microsoft.ServiceBus/namespaces/authorizationRules@2017-04-01' = {
  parent: ServiceBus
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource ServiceBusName_start_transcription_queue 'Microsoft.ServiceBus/namespaces/queues@2017-04-01' = {
  parent: ServiceBus
  name: 'start_transcription_queue'
  properties: {
    lockDuration: 'PT4M'
    maxSizeInMegabytes: 5120
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 1
    status: 'Active'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource ServiceBusName_fetch_transcription_queue 'Microsoft.ServiceBus/namespaces/queues@2017-04-01' = {
  parent: ServiceBus
  name: 'fetch_transcription_queue'
  location: resourceGroup().location
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 5120
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 5
    status: 'Active'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource ServiceBusName_fetch_transcription_queue_FetchTranscription 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2017-04-01' = {
  parent: ServiceBusName_fetch_transcription_queue
  name: 'FetchTranscription'
  location: resourceGroup().location
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
  dependsOn: [
    ServiceBus
    ServiceBusName_RootManageSharedAccessKey
  ]
}

resource ServiceBusName_start_transcription_queue_StartTranscription 'Microsoft.ServiceBus/namespaces/queues/authorizationRules@2017-04-01' = {
  parent: ServiceBusName_start_transcription_queue
  name: 'StartTranscription'
  location: resourceGroup().location
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
  dependsOn: [
    ServiceBus
    ServiceBusName_RootManageSharedAccessKey
  ]
}

resource EventGridSystemTopic 'Microsoft.EventGrid/systemTopics@2020-04-01-preview' = {
  name: EventGridSystemTopicName
  location: resourceGroup().location
  properties: {
    source: StorageAccount_resource.outputs.resourceId
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource EventGridSystemTopicName_BlobCreatedEvent 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2020-04-01-preview' = {
  parent: EventGridSystemTopic
  name: 'BlobCreatedEvent'
  properties: {
    destination: {
      endpointType: 'ServiceBusQueue'
      properties: {
        resourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ServiceBus/namespaces/${ServiceBusName}/queues/start_transcription_queue'
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      advancedFilters: [
        {
          operatorType: 'StringBeginsWith'
          key: 'Subject'
          values: [
            '/blobServices/default/containers/${AudioInputContainer}/blobs'
          ]
        }
        {
          operatorType: 'StringContains'
          key: 'data.api'
          values: [
            'FlushWithClose'
            'PutBlob'
            'PutBlockList'
            'CopyBlob'
          ]
        }
      ]
    }
    labels: []
    eventDeliverySchema: 'EventGridSchema'
  }
  dependsOn: [
    StorageAccount_resource
    ServiceBusName_start_transcription_queue
  ]
}
