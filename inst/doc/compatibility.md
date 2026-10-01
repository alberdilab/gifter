# gifter v1 compatibility contract

This is the compatibility policy intended to take effect with gifter 1.0.0.
The current 0.7 series enforces the database checks and result contracts below
so that the promise is tested before it is made. A positive GIFT call remains a
claim about encoded capability only; compatibility never widens that claim to
activity, phenotype, flux, or environmental relevance.

## Public functions and arguments

The public R API is the set of functions exported in `NAMESPACE` and documented
in the package reference. Within a 1.x series:

- exported function names will not be removed or renamed;
- documented argument names and their biological meaning will remain valid;
- calls using documented named arguments will continue to work;
- optional arguments and new return fields may be added, and stricter checks
  may reject inputs that were always invalid or biologically indefensible;
- bug fixes may change an incorrect result, with the reason and effect recorded
  in `CHANGELOG.md`.

Code that calls functions positionally remains valid for the existing argument
order, but named arguments are the forward-compatible form when a call uses
more than its first one or two parameters. Unexported functions, constants,
primary keys, SQL query plans, progress internals, and HTML/CSS structure are
not public API.

## Result classes and stable fields

The following S3 classes and core top-level fields are public in v1. New fields
may be added. Columns documented by an accessor or function are public; columns
that expose SQLite primary keys or are explicitly described as internal are
not. This avoids freezing incidental relational columns while keeping every
biological result and its trace readable.

| Class | Stable core fields |
|---|---|
| `gifter_genome` | `gifts`, `routes`, `route_reactions`, `reactions`, `systems`, `components`, `evidence`, `structural`, `regulatory`, `defense`, `marker_map`, `observed_markers`, `database_version` |
| `gifter_reaction_result` | `reactions`, `systems`, `components`, `evidence`, `marker_map`, `observed_markers`, `database_version` |
| `gifter_community` | `genome_id`, `gift_id`, `matrix`, `results`, `database_version` |
| `gifter_frame` | `gift_id`, `label`, `filters`, `bounded`, `database_version` |
| `gifter_traits` | `metrics`, `trace`, `frames`, `database_version` |
| `gifter_dataset` | `catalogue`, `genome_id`, `sample_id`, `abundance`, `metadata`, `database_version` |
| `gifter_dataset_traits` | `metrics`, `catalogue_metrics`, `trace`, `frames`, `sample_id`, `genome_id`, `metadata`, `database_version` |
| `gifter_network` | `nodes`, `edges`, `metrics`, `frame`, `database_version` |
| `gifter_dataset_network` | `nodes`, `edges`, `metrics`, `frame`, `sample_id`, `detection`, `database_version` |

Metric tables keep the documented traceability columns: target, metric, value,
unit, numerator, denominator, assessable count, reference frame, database
version, and derivation method. Trace tables keep target, metric, reference
frame, GIFT, and contribution. Type-specific diagnostic tables may gain columns
as their model becomes more expressive. Consumers should select documented
columns by name rather than assume a fixed column position or reject additions.

## Three independent versions

The package version identifies R code and the public API. The gifter database
version identifies curated biological content. The schema version identifies
the relational contract. None is inferred from either of the others, and a
change to one does not automatically require a change to all three.

Package 0.7.0, and the intended initial 1.x implementation, support schema 7.
A later package may list more than one supported schema during a migration.
Every connection is checked before a query: an unsupported schema fails with
an error naming the version found, the versions supported, and the remedies.
A missing or malformed `database_release` row is reported as an incompatible
gifter database rather than failing later in an unrelated SQL query.

A biological database release is compatible when it was compiled against a
schema version the installed package supports. Changing curated content under
the same schema does not require a package release. Changing the relational
contract requires a schema bump and coordinated package support.

## Custom databases

`gifter_db_connect(path)` accepts a SQLite file produced by
`build_gifter_database()`. An already-open custom DBI connection may also be
passed to public functions when it exposes the same schema contract. Custom
databases must contain exactly one readable `database_release` row and use a
supported schema version. Assigning `schema_version = 7` to an unrelated or
partially constructed database does not make it compatible; the supported way
to build one is from validated TSV sources with the package compiler.

Connections opened by `gifter_db_connect()` are read-only by default.
`evaluate_gifts_community()` takes one immutable SQLite snapshot for the run.
A non-SQLite custom DBI connection cannot use SQLite's backup mechanism and is
therefore evaluated sequentially on that one connection.

## Deprecation

A public function, argument, class, stable field, or established value will be
soft-deprecated before removal. The warning will name the replacement and the
changelog will state the reason and effect. The compatibility target is at
least one minor release of warning before removal, with removal normally held
for the next major release. Immediate removal is reserved for a security,
corruption, or biologically invalidating defect that cannot safely retain a
compatibility path; such an exception must be explicit in the changelog.
