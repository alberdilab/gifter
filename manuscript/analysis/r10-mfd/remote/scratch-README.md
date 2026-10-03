# gifter R10b Microflora Danica run on Mjolnir

This scratch project acquires the pinned Microflora Danica archives, extracts
the 5,518 deposited 95% ANI representatives, annotates them with the existing
Drakkar 2.6.6 environment, and prepares a checksum-verified local transfer.

The full 19,253-MAG Sylph profiles are collapsed to `secondary_cluster` only in
the local analysis. Drakkar receives exactly one deposited representative per
cluster. The current compiled gifter database and marker catalogue were copied
at submission and return with the transfer; habitat metadata is never an
annotation input.

Important sentinels and logs:

```text
tasks/01-input-acquisition/manifests/acquisition-job.id
tasks/01-input-acquisition/manifests/acquisition.complete
tasks/01-input-acquisition/logs/acquire-*.{out,err}
tasks/02-drakkar-annotation/logs/drakkar-driver-metadata.tsv
tasks/03-result-transfer/logs/workflow-driver.log
tasks/03-result-transfer/transfer-job.id
tasks/03-result-transfer/transfer.complete
tasks/03-result-transfer/transfer-manifest.tsv
```

Nothing under this path is backed up. The local repository keeps the source
manifest, locked panels, scripts and fetched compact transfer.
