# Agent instructions for `/projects/alberdilab/scratch/jpl786`

- Use this root for new Mjolnir compute work unless the user names another
  location.
- Create multi-step work under `projects/<project>/` and standalone jobs under
  `tasks/<task>/`. Give separable stages within a project their own
  `tasks/<task>/` directory.
- Treat everything here as non-backed-up and replaceable. Copy scripts,
  manifests, checksums and compact final results to a durable repository.
- Reuse shared read-only databases and existing conda environments when they
  match the pinned workflow; do not reinstall tools or duplicate multi-gigabyte
  resources without an explicit reason.
- Never move, delete or overwrite another project while consolidating the
  workspace. Existing top-level directories belong to their creators.
- Record exact software versions, database releases, scheduler commands and
  checksums before reporting completion.
