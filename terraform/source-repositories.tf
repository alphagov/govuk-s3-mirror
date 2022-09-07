# For GitHub Actions to push the repository to GCP

resource "google_sourcerepo_repository" "govuk_s3_mirror" {
  name = "alphagov/govuk-s3-mirror"
}

resource "google_service_account" "source_repositories_github" {
  account_id   = "source-repositories-github"
  display_name = "Source Repositories Service Account for GitHub"
  description  = "Service account for pushing git repositories from GitHub Actions"
}

resource "google_sourcerepo_repository_iam_member" "writer" {
  repository = google_sourcerepo_repository.govuk_s3_mirror.name
  role       = "roles/writer"
  member     = "serviceAccount:${google_service_account.source_repositories_github.email}"
}
