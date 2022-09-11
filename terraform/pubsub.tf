# Subscribe to own topic
resource "google_pubsub_subscription" "govuk_integration_database_backups" {
  name  = "govuk-integration-database-backups"
  topic = google_pubsub_topic.govuk_integration_database_backups.name

  message_retention_duration = "604800s" # 604800 seconds is 7 days
  retain_acked_messages      = true

  expiration_policy {
    ttl = "" # empty string is 'never'
  }

  enable_message_ordering    = false
}
