# ==============================
# A PubSub topic in this project
# ==============================
moved {
  from = google_pubsub_topic.govuk_integration_database_backups
  to   = google_pubsub_topic.govuk_database_backups
}
resource "google_pubsub_topic" "govuk_database_backups" {
  name                       = "govuk-database-backups"
  message_retention_duration = "604800s" # 604800 seconds is 7 days
  message_storage_policy {
    allowed_persistence_regions = [
      var.region,
    ]
  }
}

// Allow the bucket to send notifications to topic
data "google_storage_project_service_account" "default" {}
data "google_iam_policy" "pubsub_topic-govuk_database_backups" {
  binding {
    role = "roles/pubsub.publisher"
    members = [
      "serviceAccount:${data.google_storage_project_service_account.default.email_address}"
    ]
  }
}

moved {
  from = google_pubsub_topic_iam_policy.govuk_integration_database_backups
  to   = google_pubsub_topic_iam_policy.govuk_database_backups
}
resource "google_pubsub_topic_iam_policy" "govuk_database_backups" {
  topic       = google_pubsub_topic.govuk_database_backups.name
  policy_data = data.google_iam_policy.pubsub_topic-govuk_database_backups.policy_data
}

# Notify the topic from the bucket
moved {
  from = google_storage_notification.govuk_integration_database_backups
  to   = google_storage_notification.govuk_database_backups
}
resource "google_storage_notification" "govuk_database_backups" {
  bucket         = google_storage_bucket.govuk_database_backups.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.govuk_database_backups.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_database_backups]
}

# Subscribe to the topic (so that it can be monitored in the console)
moved {
  from = google_pubsub_subscription.govuk_integration_database_backups
  to   = google_pubsub_subscription.govuk_database_backups
}
resource "google_pubsub_subscription" "govuk_database_backups" {
  name  = "govuk-database-backups"
  topic = google_pubsub_topic.govuk_database_backups.name

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

# Notify the topic from the bucket
moved {
  from = google_storage_notification.govuk_integration_database_backups-govuk_knowledge_graph
  to   = google_storage_notification.govuk_database_backups-govuk_knowledge_graph
}
resource "google_storage_notification" "govuk_database_backups-govuk_knowledge_graph" {
  bucket         = google_storage_bucket.govuk_database_backups.name
  payload_format = "JSON_API_V1"
  topic          = "/projects/govuk-knowledge-graph/topics/govuk-database-backups"
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_database_backups]
}

# =======================================================
# A PubSub topic in the govuk-knowledge-graph-staging project
# =======================================================

# Notify the topic from the bucket
moved {
  from = google_storage_notification.govuk_integration_database_backups-govuk_knowledge_graph_staging
  to   = google_storage_notification.govuk_database_backups-govuk_knowledge_graph_staging
}
resource "google_storage_notification" "govuk_database_backups-govuk_knowledge_graph_staging" {
  bucket         = google_storage_bucket.govuk_database_backups.name
  payload_format = "JSON_API_V1"
  topic          = "/projects/govuk-knowledge-graph-staging/topics/govuk-database-backups"
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_database_backups]
}

# =======================================================
# A PubSub topic in the govuk-knowledge-graph-dev project
# =======================================================

# Notify the topic from the bucket
moved {
  from = google_storage_notification.govuk_integration_database_backups-govuk_knowledge_graph_dev
  to   = google_storage_notification.govuk_database_backups-govuk_knowledge_graph_dev
}
resource "google_storage_notification" "govuk_database_backups-govuk_knowledge_graph_dev" {
  bucket         = google_storage_bucket.govuk_database_backups.name
  payload_format = "JSON_API_V1"
  topic          = "/projects/govuk-knowledge-graph-dev/topics/govuk-backups"
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_database_backups]
}

# =========================================================
# Notify a PubSub topic in the govuk-analytics-test project
# =========================================================
resource "google_storage_notification" "support_api_backup_staging" {
  bucket             = google_storage_bucket.govuk_database_backups.name
  payload_format     = "JSON_API_V1"
  topic              = "projects/govuk-analytics-test/topics/support-api-backup-staging"
  event_types        = ["OBJECT_FINALIZE"]
  object_name_prefix = "support-api-postgres/"
}

# =========================================================
# Notify a PubSub topic in the govuk-user-feedback project
# =========================================================
resource "google_storage_notification" "govuk_user_feedback" {
  bucket             = google_storage_bucket.govuk_database_backups.name
  payload_format     = "JSON_API_V1"
  topic              = "projects/govuk-user-feedback/topics/support-api-backup-staging"
  event_types        = ["OBJECT_FINALIZE"]
  object_name_prefix = "support-api-postgres/"
}

# =========================================================
# Notify a PubSub topic in the govuk-user-feedback-dev project
# =========================================================
resource "google_storage_notification" "govuk_user_feedback_dev" {
  bucket             = google_storage_bucket.govuk_database_backups.name
  payload_format     = "JSON_API_V1"
  topic              = "projects/govuk-user-feedback-dev/topics/support-api-backup-staging"
  event_types        = ["OBJECT_FINALIZE"]
  object_name_prefix = "support-api-postgres/"
}
