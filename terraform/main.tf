terraform {
  required_version = ">=1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0"
    }
  }
}
provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg1" {
  name     = "cloud-resume0136"
  location = "eastus"
}

resource "azurerm_storage_account" "storage-account" {
  name                             = "cloudresumestorage0316"
  location                         = azurerm_resource_group.rg1.location
  resource_group_name              = azurerm_resource_group.rg1.name
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false

  static_website {
    error_404_document = "404.html"
    index_document     = "index.html"
  }
}

resource "azurerm_service_plan" "app-service-plan" {
  name                = "ASP-cloudresume0136-8c15"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_application_insights" "app-insights" {
  name                = "cloudresumetest"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  application_type    = "web"
  sampling_percentage = 0
  workspace_id        = "/subscriptions/e7384867-7ada-401e-88d0-1ba9c83fe9e9/resourceGroups/DefaultResourceGroup-EUS/providers/Microsoft.OperationalInsights/workspaces/DefaultWorkspace-e7384867-7ada-401e-88d0-1ba9c83fe9e9-EUS"
}

resource "azurerm_linux_function_app" "resume-function-app" {
  name                       = "camryn-cloud-resume"
  resource_group_name        = azurerm_resource_group.rg1.name
  location                   = azurerm_resource_group.rg1.location
  storage_account_name       = azurerm_storage_account.storage-account.name
  storage_account_access_key = azurerm_storage_account.storage-account.primary_access_key
  service_plan_id            = azurerm_service_plan.app-service-plan.id

  app_settings = {
    "AzureWebJobsFeatureFlags"      = "EnableWorkerIndexing"
    "AzureWebJobsSecretStorageType" = "files"
    "CosmosDbConnectionSetting"     = var.cosmos_db_connection_string
  }
  builtin_logging_enabled = false
  client_certificate_mode = "Required"
  https_only              = true
  tags = {
    "hidden-link: /app-insights-conn-string"         = "InstrumentationKey=b5331654-f02f-4b5a-bb54-a2b2f3800333;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/"
    "hidden-link: /app-insights-instrumentation-key" = "b5331654-f02f-4b5a-bb54-a2b2f3800333"
    "hidden-link: /app-insights-resource-id"         = "/subscriptions/e7384867-7ada-401e-88d0-1ba9c83fe9e9/resourceGroups/cloud-resume0136/providers/microsoft.insights/components/camryn-cloud-resume"
  }

  site_config {
    application_insights_connection_string = var.application_insights_connection_string
    ftps_state                             = "FtpsOnly"
    
    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins = [
        "*",
      ]
      support_credentials = false
    }
  }
}

resource "azurerm_function_app_function" "https-trigger" {
  name = "http_trigger"
  function_app_id = azurerm_linux_function_app.resume-function-app.id
  config_json     = jsonencode(
            {
               bindings          = [
                   {
                       authLevel = "ANONYMOUS"
                       direction = "IN"
                       name      = "req"
                       route     = "http_trigger"
                       type      = "httpTrigger"
                    },
                   {
                       direction = "OUT"
                       name      = "$return"
                       type      = "http"
                    },
                ]
               entryPoint        = "http_trigger"
               functionDirectory = "/home/site/wwwroot"
               language          = "python"
               name              = "http_trigger"
               scriptFile        = "function_app.py"
            }
        )
}
