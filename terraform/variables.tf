variable "application_insights_connection_string" {
  description = "Connection string for the application insights"
  type        = string
  sensitive   = true
}

variable "cosmos_db_connection_string" {
  description = "Connection String for Cosmos DB"
  type = string
  sensitive = true 
}