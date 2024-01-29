# Mirror on the Google Cloud Platform of some GOV.UK buckets from AWS

Repository of the [Google Cloud
Project](https://console.cloud.google.com/welcome?project=govuk-s3-mirror).
GOV.UK saves nightly database backups to an AWS S3 bucket.  This repo configures
a Google Cloud Platform project to mirror that bucket, so that other services
hosted on GCP can easily access it.

## Documentation

[GOV.UK Data Community Technical Documentation](https://docs.data-community.publishing.service.gov.uk/analysis/govgraph/pipeline-v2/)

## Links to GCP projects

* [Production](https://console.cloud.google.com/welcome?project=govuk-s3-mirror)

## IAM roles/permissions required in other projects

This project requires IAM roles and permissions in GOV.UK's AWS infrastructure, created
by [this pull request](https://github.com/alphagov/govuk-aws/pull/1630).

## How to subscribe to notifications that new files are available

When a database backup file is newly available in the bucket in Google Cloud
Platform, the bucket publishes a notification to PubSub topics in other
projects.  This is configured by the blocks at the bottom of the file
`/terraform/pubsub.tf`.

To receive notifications in a new project:

1. Create a PubSub topic in the new project
2. Give this project permission to publish to the PubSub topic by giving the
   service account
   `service-384988117066@gs-project-accounts.iam.gserviceaccount.com` the role
   `roles/pubsub.publisher` in relation to the PubSub topic.
3. Add a `resource` to the end of the file `/terraform/pubsub.tf` in this
   repository, similar to the existing resources, but changing the `topic` to
   the new one.
4. Deploy the changes to this project by running `terraform apply`.

Below is an example terraform configuration in a project that receives notifications from
this project, copied from
https://github.com/alphagov/govuk-knowledge-graph-gcp/blob/main/terraform/pubsub.tf.

```terraform
resource "google_pubsub_topic" "govuk_integration_database_backups" {
  name                       = "govuk-integration-database-backups"
  message_retention_duration = "604800s" # 604800 seconds is 7 days
  message_storage_policy {
    allowed_persistence_regions = [
      var.region,
    ]
  }
}

// Allow the govuk-s3-mirror project's bucket to publish to this topic
data "google_iam_policy" "pubsub_topic-govuk_integration_database_backups" {
  binding {
    role = "roles/pubsub.publisher"
    members = [
      "serviceAccount:service-384988117066@gs-project-accounts.iam.gserviceaccount.com"
    ]
  }
}

resource "google_pubsub_topic_iam_policy" "govuk_integration_database_backups" {
  topic       = google_pubsub_topic.govuk_integration_database_backups.name
  policy_data = data.google_iam_policy.pubsub_topic-govuk_integration_database_backups.policy_data
}

# Subscribe to the topic
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
```

Below is the `resource` in the file `/terraform/pubsub.tf` that corresponds to
the example above.

```terraform
# Notify the topic from the bucket
resource "google_storage_notification" "govuk_integration_database_backups-govuk_knowledge_graph" {
  bucket         = google_storage_bucket.govuk-integration-database-backups.name
  payload_format = "JSON_API_V1"
  topic          = "/projects/govuk-knowledge-graph/topics/govuk-integration-database-backups"
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_policy.govuk_integration_database_backups]
}
```

## How to include a new file

Not every file in the S3 bucket is transferred to Google Cloud Platform.  A
filter is defined in `/terraform/transfer.tf`, in the resource that is partially
copied out below. To include a new file, add its prefix to the array of
`include_prefixes`.

The filter is on the first part of the name of the object, called the 'prefix'.
Folder names are included in the object name, so in the filters below, every
object in the folder `publishing-api-postgres/` is included.

```terraform
resource "google_storage_transfer_job" "govuk-integration-database-backups" {
  description = "Mirror the GOV.UK S3 bucket govuk-integration-database-backups"

  transfer_spec {
    object_conditions {
      include_prefixes = [
        "content-store-postgres/",
        "publishing-api-postgres/",
        "support-api-postgres/",
        "mongo-api/",
      ]
    }
```

## Who to contact

This project is not currently owned by any team in the GOV.UK programme. The
people who are most likely to be able to help are in the Slack channel
`#data-engineering`.

## Licence

Unless stated otherwise, the codebase is released under [the MIT License][mit].
This covers both the codebase and any sample code in the documentation.

The documentation is [© Crown copyright][copyright] and available under the terms
of the [Open Government 3.0][ogl] licence.
