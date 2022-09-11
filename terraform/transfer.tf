# Nightly transfer from AWS S3

data "google_storage_transfer_project_service_account" "default" {
}

resource "google_storage_bucket" "govuk-integration-database-backups" {
  name                        = "${var.project_id}_govuk-integration-database-backups" # Must be globally unique
  force_destroy               = false                                                  # terraform won't delete the bucket unless it is empty
  storage_class               = "STANDARD"                                             # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  location                    = var.location
  versioning {
    enabled = false
  }
}

# Allow the transfer job to use the bucket via its service account
data "google_iam_policy" "bucket_govuk-integration-database-backups" {
  binding {
    role = "roles/storage.admin"
    members = [
      "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}",
    ]
  }

  binding {
    role = "roles/storage.objectViewer"
    members = [
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-products@digital.cabinet-office.gov.uk",
      "group:data-insights@digital.cabinet-office.gov.uk",
      "user:matthew.gregory@digital.cabinet-office.gov.uk",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketOwner"
    members = [
      "projectEditor:govuk-s3-mirror",
      "projectOwner:govuk-s3-mirror",
    ]
  }

  binding {
    role = "roles/storage.legacyBucketReader"
    members = [
      "projectViewer:govuk-s3-mirror",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectOwner"
    members = [
      "projectEditor:govuk-s3-mirror",
      "projectOwner:govuk-s3-mirror",
    ]
  }

  binding {
    role = "roles/storage.legacyObjectReader"
    members = [
      "projectViewer:govuk-s3-mirror",
    ]
  }

}

resource "google_storage_bucket_iam_policy" "govuk-integration-database-backups" {
  bucket      = google_storage_bucket.govuk-integration-database-backups.name
  policy_data = data.google_iam_policy.bucket_govuk-integration-database-backups.policy_data
}

resource "google_storage_transfer_job" "govuk-integration-database-backups" {
  description = "Mirror the GOV.UK S3 bucket govuk-integration-database-backups"

  transfer_spec {
    object_conditions {
      include_prefixes = [
        "publishing-api-postgres/",
        "support-api-postgres/",
        "mongo-api/",
      ]
    }
    transfer_options {
      overwrite_objects_already_existing_in_sink = false
      delete_objects_unique_in_sink              = true
      delete_objects_from_source_after_transfer  = false
    }
    aws_s3_data_source {
      bucket_name = "govuk-integration-database-backups"
      role_arn    = "arn:aws:iam::210287912431:role/google-s3-mirror"
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.govuk-integration-database-backups.name
    }
  }

  schedule {
    schedule_start_date {
      year  = 2022
      month = 09
      day   = 07
    }
    start_time_of_day {
      hours   = 00
      minutes = 00
      seconds = 00
      nanos   = 0
    }
    repeat_interval = "3600s"
  }
}

# Send notifications to pubusb
resource "google_pubsub_topic" "govuk_integration_database_backups" {
  name                       = "govuk-integration-database-backups"
  message_retention_duration = "604800s" # 604800 seconds is 7 days
  message_storage_policy {
    allowed_persistence_regions = [
      var.region,
    ]
  }
}

resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.govuk-integration-database-backups.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.govuk_integration_database_backups.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_integration_database_backups]
}

// Enable notifications by giving the correct IAM permission to the unique service account.
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
