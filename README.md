# Mirror on the Google Cloud Platform of some GOV.UK buckets from AWS

Repository of the [Google Cloud
Project](https://console.cloud.google.com/welcome?project=govuk-s3-mirror).
GOV.UK saves nightly database backups to an AWS S3 bucket.  This repo configures
a Google Cloud Platform project to mirror that bucket, so that other services
hosted on GCP can easily access it.

## Terraform

Terraform has been configured to "plan" on any push to a pull request, and
"apply" on any merge to the "main" branch.

To run locally, provide your own github token from `gh auth status
--show-token`.

```sh
export GITHUB_TOKEN=$( \
  gh auth status --show-token 2>&1 >/dev/null \
  | grep "oken" -A 0 -B 0 \
  | grep -oP '\w+$' \
)
terraform apply
```

You will also have to [set the project to be
billed](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/set-quota-project)
by the Google Cloud Storage Transfer service.  This only works if you have also
just re-authorised the shell.

```sh
gcloud auth application-default login
gcloud auth application-default set-quota-project govuk-s3-mirror
```

If retrospectively terraforming a resource that already exists, you'll have to
import it first.  That probably goes for the repository, branch, collaborator,
etc.  One does not simply bootstrap a terraform configuration.

## Authentication

There must be a repository secret called `TERRAFORM_TOKEN_GITHUB` that is a
PAT (personal access token) with full `repo` and `admin:org` permissions, and
that belongs to an admin of this repository.

## Licence

Unless stated otherwise, the codebase is released under [the MIT License][mit].
This covers both the codebase and any sample code in the documentation.

The documentation is [© Crown copyright][copyright] and available under the terms
of the [Open Government 3.0][ogl] licence.
