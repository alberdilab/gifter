# jpl786 Mjolnir scratch workspace

This is the default location for agent-created compute work on Mjolnir:

`/projects/alberdilab/scratch/jpl786/`

It is high-capacity, non-backed-up storage. Durable source code, compact final
results and irreplaceable provenance must be copied to a backed-up repository
or archive. Do not place new compute projects under
`/projects/alberdilab/people/jpl786/` by default.

## Layout

- `projects/<project>/`: one self-contained directory per multi-step project
- `tasks/<task>/`: one self-contained directory per standalone task
- each project may use `tasks/<task>/` subdirectories for separable stages
- `software/`: pinned command-line installations only when no suitable shared
  conda environment already exists
- `environments/`: project-specific environments not already provided in the
  shared lab environment store
- `cache/`: reusable but replaceable downloads
- `logs/`: cross-project operational logs
- `tmp/`: replaceable temporary data

Existing directories are not moved automatically. Consolidation means that new
projects and tasks follow this layout and `$HOME/scratch` points here; migration
of old projects is a separate, explicit operation.
