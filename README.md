# Mirror on the Google Cloud Platform of some GOV.UK buckets from AWS

Repository of the [Google Cloud
Project](https://console.cloud.google.com/welcome?project=govuk-s3-mirror).
GOV.UK saves nightly database backups to an AWS S3 bucket.  This repo configures
a Google Cloud Platform project to mirror that bucket, so that other services
hosted on GCP can easily access it.


## Licence

Unless stated otherwise, the codebase is released under [the MIT License][mit].
This covers both the codebase and any sample code in the documentation.

The documentation is [© Crown copyright][copyright] and available under the terms
of the [Open Government 3.0][ogl] licence.
