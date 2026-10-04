#!/usr/bin/env python3
"""Audit K01752 architecture ambiguity against NCBIfam 20.0 profiles.

Run from the package root. Public KEGG and NCBIfam inputs stay in the ignored
cache; the two small result tables are reviewable curation evidence. --offline
reuses the exact cached inputs without contacting either resource.
"""

import argparse
import csv
import hashlib
import subprocess
import time
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path


PROFILES = ("TIGR00718.1", "TIGR00719.1", "TIGR00720.1")
PINNED_RELEASE = "hmm_PGAP/20.0"
FRAME = Path("manuscript/analysis/output/kegg-genome-set.tsv")
CACHE = Path("data-raw/reference/.cache/serine-deamination")
OUT = Path("data-raw/reference")


def download(url, path, offline):
    if path.exists() and path.stat().st_size:
        return path
    if offline:
        raise RuntimeError(f"missing offline input: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    last_error = None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=45) as response:
                payload = response.read()
            if not payload:
                raise RuntimeError(f"empty response: {url}")
            path.write_bytes(payload)
            time.sleep(0.2)
            return path
        except Exception as error:
            last_error = error
            time.sleep(attempt + 1)
    raise RuntimeError(f"could not fetch {url}: {last_error}")


def read_frame():
    with FRAME.open(newline="") as handle:
        rows = csv.DictReader(handle, delimiter="\t")
        return {
            row["org"]
            for row in rows
            if row["prokaryote"].lower() in {"true", "t", "1"}
        }


def read_links(path, frame):
    genes = defaultdict(list)
    with path.open() as handle:
        for line in handle:
            _ko, gene = line.rstrip("\n").split("\t")
            org = gene.split(":", 1)[0]
            if org in frame:
                genes[org].append(gene)
    return {org: sorted(set(ids)) for org, ids in genes.items()}


def fasta_records(path):
    records = {}
    gene = None
    parts = []
    with path.open() as handle:
        for line in handle:
            if line.startswith(">"):
                if gene is not None:
                    records[gene] = "".join(parts)
                gene = line[1:].split()[0]
                parts = []
            else:
                parts.append(line.strip())
    if gene is not None:
        records[gene] = "".join(parts)
    return records


def sample_genomes(k17, n):
    groups = {
        "one_K01752_gene": [org for org, ids in k17.items() if len(ids) == 1],
        "two_K01752_genes": [org for org, ids in k17.items() if len(ids) == 2],
        "three_plus_K01752_genes": [org for org, ids in k17.items() if len(ids) >= 3],
    }
    selected = {}
    for label, orgs in groups.items():
        ranked = sorted(
            orgs,
            key=lambda org: hashlib.sha256(
                f"gifter-serine-v1:{org}".encode()
            ).digest(),
        )
        selected.update({org: label for org in ranked[:n]})
    for org in ("eco", "bsu"):
        if org in k17:
            selected[org] = "named_control"
    return selected


def get_sample_sequences(genes, offline):
    sequences = {}
    chunks = [genes[i : i + 10] for i in range(0, len(genes), 10)]
    for index, chunk in enumerate(chunks, 1):
        key = hashlib.sha256("+".join(chunk).encode()).hexdigest()[:16]
        path = CACHE / "kegg" / "aaseq" / f"{key}.faa"
        url = "https://rest.kegg.jp/get/" + "+".join(chunk) + "/aaseq"
        download(url, path, offline)
        sequences.update(fasta_records(path))
        if index % 10 == 0 or index == len(chunks):
            print(f"Protein sequence batches: {index}/{len(chunks)}", flush=True)
    missing = set(genes) - set(sequences)
    if missing:
        raise RuntimeError(f"KEGG returned no sequence for: {sorted(missing)}")
    return sequences


def profile_hits(profile, fasta, offline):
    hmm = CACHE / "ncbifam" / f"{profile}.HMM"
    url = f"https://ftp.ncbi.nlm.nih.gov/hmm/current/hmm_PGAP.HMM/{profile}.HMM"
    download(url, hmm, offline)
    header = hmm.read_text().split("HMM ", 1)[0]
    if f"ACC   {profile}\n" not in header or "GA    " not in header:
        raise RuntimeError(f"unexpected accession or missing gathering cutoff: {hmm}")
    tblout = CACHE / f"{profile}.sample.tbl"
    subprocess.run(
        ["hmmsearch", "--noali", "--cut_ga", "--tblout", str(tblout),
         str(hmm), str(fasta)],
        stdout=subprocess.DEVNULL,
        check=True,
    )
    hits = {}
    with tblout.open() as handle:
        for line in handle:
            if line.startswith("#") or not line.strip():
                continue
            fields = line.split()
            hits[fields[0]] = float(fields[5])
    return hits


def write_table(path, rows, columns):
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, delimiter="\t",
                                lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--offline", action="store_true")
    parser.add_argument("--sample-per-stratum", type=int, default=40)
    args = parser.parse_args()
    if args.sample_per_stratum < 1:
        parser.error("--sample-per-stratum must be positive")

    notes = download("https://ftp.ncbi.nlm.nih.gov/hmm/current/RELEASE_NOTES.txt",
                     CACHE / "ncbifam" / "RELEASE_NOTES.txt", args.offline)
    release_lines = [line for line in notes.read_text().splitlines()
                     if "Release number/name" in line]
    if len(release_lines) != 1 or release_lines[0].split(":", 1)[-1].strip() != PINNED_RELEASE:
        raise RuntimeError("NCBIfam current release differs from the assessed "
                           f"{PINNED_RELEASE}: {release_lines}")

    frame = read_frame()
    k17 = read_links(download("https://rest.kegg.jp/link/genes/ko:K01752",
                              CACHE / "kegg" / "K01752.tsv", args.offline), frame)
    k179 = read_links(download("https://rest.kegg.jp/link/genes/ko:K17989",
                               CACHE / "kegg" / "K17989.tsv", args.offline), frame)
    selected = sample_genomes(k17, args.sample_per_stratum)
    genes = sorted({gene for org in selected for gene in k17[org]})
    sequences = get_sample_sequences(genes, args.offline)
    fasta = CACHE / "sample-proteins.faa"
    with fasta.open("w") as handle:
        for gene in genes:
            handle.write(f">{gene}\n{sequences[gene]}\n")
    hits = {profile: profile_hits(profile, fasta, args.offline)
            for profile in PROFILES}

    gene_rows = []
    genome_rows = []
    for org, group in sorted(selected.items()):
        member_hits = {p: 0 for p in PROFILES}
        for gene in k17[org]:
            gene_hits = [p for p in PROFILES if gene in hits[p]]
            for profile in gene_hits:
                member_hits[profile] += 1
            gene_rows.append({
                "org": org, "sample_group": group, "gene_id": gene,
                "k01752_gene_count": len(k17[org]),
                "profiles": ";".join(gene_hits) or "none",
                "alpha_score": hits[PROFILES[0]].get(gene, "NA"),
                "beta_score": hits[PROFILES[1]].get(gene, "NA"),
                "single_chain_score": hits[PROFILES[2]].get(gene, "NA"),
            })
        genome_rows.append({
            "org": org, "sample_group": group,
            "k01752_gene_count": len(k17[org]),
            "has_k17989": int(org in k179),
            "alpha_hits": member_hits[PROFILES[0]],
            "beta_hits": member_hits[PROFILES[1]],
            "single_chain_hits": member_hits[PROFILES[2]],
            "revised_supported_on_k01752_genes": int(
                org in k179 or member_hits[PROFILES[2]] > 0 or
                (member_hits[PROFILES[0]] > 0 and member_hits[PROFILES[1]] > 0)
            ),
        })

    OUT.mkdir(parents=True, exist_ok=True)
    write_table(OUT / "serine-deamination-gene-audit.tsv", gene_rows,
                list(gene_rows[0]))
    write_table(OUT / "serine-deamination-genome-audit.tsv", genome_rows,
                list(genome_rows[0]))

    counts = Counter(len(ids) for ids in k17.values())
    supported = sum(r["revised_supported_on_k01752_genes"] for r in genome_rows)
    print(f"NCBIfam release: {PINNED_RELEASE} (accession versions verified)")
    print(f"Frame: {len(frame)} entries with prokaryote flag")
    print(f"K01752: {len(k17)} genomes, {sum(map(len, k17.values()))} genes")
    print(f"K01752 copy counts: {sorted(counts.items())}")
    print(f"K17989: {len(k179)} genomes; overlap: {len(k17.keys() & k179.keys())}")
    print(f"KO-only current: {len(k17.keys() | k179.keys())}; "
          f"after retiring K01752: {len(k179)}; "
          f"loss: {len(k17.keys() - k179.keys())}")
    print(f"Sample: {len(genome_rows)} genomes, {len(gene_rows)} KO genes; "
          f"revised support on those KO genes or K17989: {supported}")


if __name__ == "__main__":
    main()
