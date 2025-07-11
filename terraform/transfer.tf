# Nightly transfer from AWS S3

data "google_storage_transfer_project_service_account" "default" {
}

resource "google_storage_bucket" "govuk_database_backups" {
  name                        = "${var.project_id}_govuk-database-backups" # Must be globally unique
  force_destroy               = false                                      # terraform won't delete the bucket unless it is empty
  storage_class               = "STANDARD"                                 # https://cloud.google.com/storage/docs/storage-classes
  uniform_bucket_level_access = true
  location                    = var.location
  versioning {
    enabled = false
  }
}

# Allow the transfer job to use the bucket via its service account
data "google_iam_policy" "bucket_govuk_database_backups" {
  binding {
    role = "roles/storage.admin"
    members = [
      "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}",
    ]
  }

  binding {
    role = "roles/storage.objectViewer"
    members = [
      "group:govgraph-private-data-readers@digital.cabinet-office.gov.uk",
      "serviceAccount:gce-publishing-api@govuk-knowledge-graph-dev.iam.gserviceaccount.com",
      "serviceAccount:gce-publishing-api@govuk-knowledge-graph-staging.iam.gserviceaccount.com",
      "serviceAccount:gce-publishing-api@govuk-knowledge-graph.iam.gserviceaccount.com",
      "serviceAccount:gce-support-api@govuk-knowledge-graph-dev.iam.gserviceaccount.com",
      "serviceAccount:gce-support-api@govuk-knowledge-graph-staging.iam.gserviceaccount.com",
      "serviceAccount:gce-support-api@govuk-knowledge-graph.iam.gserviceaccount.com",
      "serviceAccount:gce-publisher@govuk-knowledge-graph-dev.iam.gserviceaccount.com",
      "serviceAccount:gce-publisher@govuk-knowledge-graph-staging.iam.gserviceaccount.com",
      "serviceAccount:gce-publisher@govuk-knowledge-graph.iam.gserviceaccount.com",
      "serviceAccount:gce-whitehall@govuk-knowledge-graph-dev.iam.gserviceaccount.com",
      "serviceAccount:gce-whitehall@govuk-knowledge-graph-staging.iam.gserviceaccount.com",
      "serviceAccount:gce-whitehall@govuk-knowledge-graph.iam.gserviceaccount.com",
      "serviceAccount:gce-asset-manager@govuk-knowledge-graph-dev.iam.gserviceaccount.com",
      "serviceAccount:gce-asset-manager@govuk-knowledge-graph-staging.iam.gserviceaccount.com",
      "serviceAccount:gce-asset-manager@govuk-knowledge-graph.iam.gserviceaccount.com",
      "serviceAccount:data-engineering@govuk-user-feedback-dev.iam.gserviceaccount.com",
      "serviceAccount:data-engineering@govuk-user-feedback.iam.gserviceaccount.com",
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

resource "google_storage_bucket_iam_policy" "govuk_database_backups" {
  bucket      = google_storage_bucket.govuk_database_backups.name
  policy_data = data.google_iam_policy.bucket_govuk_database_backups.policy_data
}

resource "google_storage_transfer_job" "govuk_database_backups" {
  description = "Mirror the GOV.UK S3 bucket govuk-staging-database-backups"

  transfer_spec {
    object_conditions {
      include_prefixes = [
        "content-store-postgres/",
        "mongo-api/",
        "publishing-api-postgres/",
        "shared-documentdb/",
        "support-api-postgres/",
        "whitehall-mysql/",
      ]
    }
    transfer_options {
      overwrite_objects_already_existing_in_sink = false
      delete_objects_unique_in_sink              = true
      delete_objects_from_source_after_transfer  = false
    }
    aws_s3_data_source {
      bucket_name = "govuk-staging-database-backups"
      role_arn    = "arn:aws:iam::696911096973:role/google-s3-mirror"
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.govuk_database_backups.name
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
