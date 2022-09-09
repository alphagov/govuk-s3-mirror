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
resource "google_storage_bucket_iam_member" "govuk-integration-database-backups_admin" {
  bucket     = google_storage_bucket.govuk-integration-database-backups.name
  role       = "roles/storage.admin"
  member     = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
  depends_on = [google_storage_bucket.govuk-integration-database-backups]
}

resource "google_storage_bucket_iam_binding" "govuk-integration-database-backups_objectViewer" {
  bucket = google_storage_bucket.govuk-integration-database-backups.name
  role   = "roles/storage.objectViewer"
  members = [
    "group:data-products@digital.cabinet-office.gov.uk",
    "group:data-insights@digital.cabinet-office.gov.uk",
  ]
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

  depends_on = [google_storage_bucket_iam_member.govuk-integration-database-backups_admin]
}
