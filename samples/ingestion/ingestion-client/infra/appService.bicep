param AddDiarization string
param AddWordLevelTimestamps string
param AppInsightsName string
param AppServicePlanName string
param AudioInputContainer string
param AudioProcessedContainer string
param AzureSpeechServicesKeySecretName string
param AzureSpeechServicesRegion string
param AzureSpeechServicesEndpointUri string
param CreateHtmlResultFile string
param CreateConsolidatedOutputFiles string
param ConsolidatedFilesOutputContainer string
param CreateAudioProcessedContainer string
param ConversationPiiCategories string
param ConversationPiiInferenceSource string
param ConversationPiiRedaction string
param ConversationSummarizationOptions string
param CompletedServiceBusConnectionString string
param CustomModelId string
param DatabaseConnectionStringSecretName string
param FetchTranscriptionBinary string
param FetchTranscriptionFunctionName string
param EndpointSuffix string
param ErrorFilesOutputContainer string
param ErrorReportOutputContainer string
param FilesPerTranscriptionJob string
param HtmlResultOutputContainer string
param JsonResultOutputContainer string
param InitialPollingDelayInMinutes string
param IsAzureGovDeployment string
param IsByosEnabledSubscription string
param KeyVaultName string
param Locale string
param MaxPollingDelayInMinutes string
param MessagesPerFunctionExecution string
param PiiCategories string
param PiiRedaction string
param ProfanityFilterMode string
param PunctuationMode string
param RetryLimit string
param SentimentAnalysis string
param ServiceBusName_fetch_transcription_queue_name string
param ServiceBusName_start_transcription_queue_name string
param ServiceBusName_RootManageSharedAccessKeyName string
param StartTranscriptionByServiceBusBinary string
param StartTranscriptionByTimerBinary string
param StartTranscriptionFunctionTimeInterval string
param StorageAccountName string
param StartTranscriptionFunctionName string
param TextAnalyticsKeySecretName string
param TextAnalyticsEndpoint string
param TimerBasedExecution bool
param UseSqlDatabase string

resource AppInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: AppInsightsName
}

resource StorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: StorageAccountName
}

resource ServiceBus 'Microsoft.ServiceBus/namespaces/authorizationRules@2017-04-01' existing = {
  name: ServiceBusName_RootManageSharedAccessKeyName
}

resource ServiceBusName_fetch_transcription_queue 'Microsoft.ServiceBus/namespaces/queues@2017-04-01' existing = {
  name: ServiceBusName_fetch_transcription_queue_name
}

resource ServiceBusName_start_transcription_queue 'Microsoft.ServiceBus/namespaces/queues@2017-04-01' existing = {
  name: ServiceBusName_start_transcription_queue_name
}

resource AppServicePlan 'Microsoft.Web/serverfarms@2018-02-01' = {
  kind: 'app'
  name: AppServicePlanName
  location: resourceGroup().location
  properties: {}
  sku: {
    name: 'EP1'
  }
}

resource StartTranscriptionFunction 'Microsoft.Web/sites@2020-09-01' = {
  name: StartTranscriptionFunctionName
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    serverFarmId: AppServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v8.0'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource StartTranscriptionFunctionName_AppSettings 'Microsoft.Web/sites/config@2020-09-01' = {
  parent: StartTranscriptionFunction
  name: 'appsettings'
  properties: {
    AddDiarization: AddDiarization
    AddWordLevelTimestamps: AddWordLevelTimestamps
    APPLICATIONINSIGHTS_CONNECTION_STRING: AppInsights.properties.ConnectionString
    AudioInputContainer: AudioInputContainer
    AzureServiceBus: ServiceBus.listKeys().primaryConnectionString
    AzureSpeechServicesKey: '@Microsoft.KeyVault(VaultName=${KeyVaultName};SecretName=${AzureSpeechServicesKeySecretName})'
    AzureSpeechServicesRegion: AzureSpeechServicesRegion
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${StorageAccountName};AccountKey=${StorageAccount.listKeys().keys[0].value};EndpointSuffix=${EndpointSuffix}'
    CustomModelId: CustomModelId
    ErrorFilesOutputContainer: ErrorFilesOutputContainer
    ErrorReportOutputContainer: ErrorReportOutputContainer
    FetchTranscriptionServiceBusConnectionString: ServiceBusName_fetch_transcription_queue.listKeys().primaryConnectionString
    FilesPerTranscriptionJob: FilesPerTranscriptionJob
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
    AzureSpeechServicesEndpointUri: AzureSpeechServicesEndpointUri
    InitialPollingDelayInMinutes: InitialPollingDelayInMinutes
    IsAzureGovDeployment: IsAzureGovDeployment
    IsByosEnabledSubscription: IsByosEnabledSubscription
    MaxPollingDelayInMinutes: MaxPollingDelayInMinutes
    Locale: Locale
    MessagesPerFunctionExecution: MessagesPerFunctionExecution
    StartTranscriptionFunctionTimeInterval: StartTranscriptionFunctionTimeInterval
    ProfanityFilterMode: ProfanityFilterMode
    PunctuationMode: PunctuationMode
    RetryLimit: RetryLimit
    StartTranscriptionServiceBusConnectionString: ServiceBusName_start_transcription_queue.listKeys().primaryConnectionString
    WEBSITE_RUN_FROM_PACKAGE: (TimerBasedExecution
      ? StartTranscriptionByTimerBinary
      : StartTranscriptionByServiceBusBinary)
  }
}

resource FetchTranscriptionFunction 'Microsoft.Web/sites@2020-09-01' = {
  name: FetchTranscriptionFunctionName
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    serverFarmId: AppServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v8.0'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource FetchTranscriptionFunctionName_AppSettings 'Microsoft.Web/sites/config@2020-09-01' = {
  parent: FetchTranscriptionFunction
  name: 'appsettings'
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: AppInsights.listKeys().ConnectionString
    PiiRedactionSetting: PiiRedaction
    SentimentAnalysisSetting: SentimentAnalysis
    AudioInputContainer: AudioInputContainer
    AzureServiceBus: ServiceBus.listKeys().primaryConnectionString
    AzureSpeechServicesKey: '@Microsoft.KeyVault(VaultName=${KeyVaultName};SecretName=${AzureSpeechServicesKeySecretName})'
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${StorageAccountName};AccountKey=${StorageAccount.listKeys().keys[0].value};EndpointSuffix=${EndpointSuffix}'
    CreateHtmlResultFile: CreateHtmlResultFile
    DatabaseConnectionString: '@Microsoft.KeyVault(VaultName=${KeyVaultName};SecretName=${DatabaseConnectionStringSecretName})'
    ErrorFilesOutputContainer: ErrorFilesOutputContainer
    ErrorReportOutputContainer: ErrorReportOutputContainer
    FetchTranscriptionServiceBusConnectionString: ServiceBusName_fetch_transcription_queue.listKeys().primaryConnectionString
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
    HtmlResultOutputContainer: HtmlResultOutputContainer
    InitialPollingDelayInMinutes: InitialPollingDelayInMinutes
    MaxPollingDelayInMinutes: MaxPollingDelayInMinutes
    JsonResultOutputContainer: JsonResultOutputContainer
    RetryLimit: RetryLimit
    StartTranscriptionServiceBusConnectionString: ServiceBusName_start_transcription_queue.listKeys().primaryConnectionString
    TextAnalyticsKey: '@Microsoft.KeyVault(VaultName=${KeyVaultName};SecretName=${TextAnalyticsKeySecretName})'
    TextAnalyticsEndpoint: TextAnalyticsEndpoint
    UseSqlDatabase: UseSqlDatabase
    WEBSITE_RUN_FROM_PACKAGE: FetchTranscriptionBinary
    CreateConsolidatedOutputFiles: CreateConsolidatedOutputFiles
    ConsolidatedFilesOutputContainer: ConsolidatedFilesOutputContainer
    CreateAudioProcessedContainer: CreateAudioProcessedContainer
    AudioProcessedContainer: AudioProcessedContainer
    PiiCategories: PiiCategories
    ConversationPiiCategories: ConversationPiiCategories
    ConversationPiiInferenceSource: ConversationPiiInferenceSource
    ConversationPiiSetting: ConversationPiiRedaction
    ConversationSummarizationOptions: ConversationSummarizationOptions
    CompletedServiceBusConnectionString: CompletedServiceBusConnectionString
  }
}

output StartTranscriptionFunctionId string = StartTranscriptionFunction.id
output FetchTranscriptionFunctionId string = FetchTranscriptionFunction.id
