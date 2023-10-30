# ==============================
# A PubSub topic in this project
# ==============================
resource "google_pubsub_topic" "govuk_integration_database_backups" {
  name                       = "govuk-integration-database-backups"
  message_retention_duration = "604800s" # 604800 seconds is 7 days
  message_storage_policy {
    allowed_persistence_regions = [
      var.region,
    ]
  }
}

// Allow the bucket to send notifications to topic
data "google_iam_policy" "pubsub_topic-govuk_integration_database_backups" {
  binding {
    role = "roles/pubsub.publisher"
    members = [
      "serviceAccount:${data.google_storage_project_service_account.default.email_address}"
    ]
  }
}

resource "google_pubsub_topic_iam_policy" "govuk_integration_database_backups" {
  topic       = google_pubsub_topic.govuk_integration_database_backups.name
  policy_data = data.google_iam_policy.pubsub_topic-govuk_integration_database_backups.policy_data
}

# Notify the topic from the bucket
resource "google_storage_notification" "govuk_integration_database_backups" {
  bucket         = google_storage_bucket.govuk-integration-database-backups.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.govuk_integration_database_backups.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_integration_database_backups]
}

# Subscribe to the topic (so that it can be monitored in the console)
resource "google_pubsub_subscription" "govuk_integration_database_backups" {
  name  = "govuk-integration-database-backups"
  topic = google_pubsub_topic.govuk_integration_database_backups.name

  message_retention_duration = "604800s" # 604800 seconds is 7 days
  retain_acked_messages      = true

  expiration_policy {
    ttl = "" # empty string is 'never'
  }

  enable_message_ordering = false
}

# ===================================================
# A PubSub topic in the govuk-knowledge-graph project
# ===================================================
data "google_pubsub_topic" "govuk_integration_database_backups-govuk_knowledge_graph" {
  project                    = "govuk-knowledge-graph"
  name                       = "govuk-integration-database-backups"
}

# Notify the topic from the bucket
resource "google_storage_notification" "govuk_integration_database_backups-govuk_knowledge_graph" {
  bucket         = google_storage_bucket.govuk-integration-database-backups.name
  payload_format = "JSON_API_V1"
  topic          = data.google_pubsub_topic.govuk_integration_database_backups-govuk_knowledge_graph.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_integration_database_backups]
}

# =======================================================
# A PubSub topic in the govuk-knowledge-graph-staging project
# =======================================================
data "google_pubsub_topic" "govuk_integration_database_backups-govuk_knowledge_graph_staging" {
  project                    = "govuk-knowledge-graph-staging"
  name                       = "govuk-integration-database-backups"
}

# Notify the topic from the bucket
resource "google_storage_notification" "govuk_integration_database_backups-govuk_knowledge_graph_staging" {
  bucket         = google_storage_bucket.govuk-integration-database-backups.name
  payload_format = "JSON_API_V1"
  topic          = data.google_pubsub_topic.govuk_integration_database_backups-govuk_knowledge_graph_staging.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_integration_database_backups]
}

# =======================================================
# A PubSub topic in the govuk-knowledge-graph-dev project
# =======================================================
data "google_pubsub_topic" "govuk_integration_database_backups-govuk_knowledge_graph_dev" {
  project                    = "govuk-knowledge-graph-dev"
  name                       = "govuk-integration-database-backups"
}

# Notify the topic from the bucket
resource "google_storage_notification" "govuk_integration_database_backups-govuk_knowledge_graph_dev" {
  bucket         = google_storage_bucket.govuk-integration-database-backups.name
  payload_format = "JSON_API_V1"
  topic          = data.google_pubsub_topic.govuk_integration_database_backups-govuk_knowledge_graph_dev.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_integration_database_backups]
}

# =========================================================
# Notify a PubSub topic in the govuk-analytics-test project
# =========================================================
resource "google_storage_notification" "support_api_backup_staging" {
  bucket             = google_storage_bucket.govuk-integration-database-backups.name
  payload_format     = "JSON_API_V1"
  topic              = "projects/govuk-analytics-test/topics/support-api-backup-staging"
  event_types        = ["OBJECT_FINALIZE"]
  object_name_prefix = "support-api-postgres/"
}

# =========================================================
# Notify a PubSub topic in the govuk-user-feedback-dev project
# =========================================================
resource "google_storage_notification" "support_api_backup_staging2" {
  bucket             = google_storage_bucket.govuk-integration-database-backups.name
  payload_format     = "JSON_API_V1"
  topic              = "projects/govuk-user-feedback-dev/topics/support-api-backup-staging"
  event_types        = ["OBJECT_FINALIZE"]
  object_name_prefix = "support-api-postgres/"
}