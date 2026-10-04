# Curation leads from the GTDB phylogenetic panel

Status: **open to-do list; nothing here has been assessed or curated.** Each
item names a GIFT definition worth re-reading, the evidence that raised it, and
the check that would settle it. No database content changed. A lead is a
question, not a diagnosis: of the three leads the phenotype benchmark produced,
one found an incomplete route inventory and one found that its own premise was
wrong ([phenotype curation leads](proposal-phenotype-curation-leads.md)).

Attempt `GEA-20261004-GTDB-NEAR-MISS-SCREEN` in
[the expansion attempts](catalogue-expansion-attempts.tsv). The row was opened
when this document was written, after the screen had run, not before it as
[the workflow](catalogue-expansion-log.md) asks.

## Where the leads come from

The manuscript's GTDB overview evaluates 696 complete bacterial genomes against
database 2026.37.1 (163 GIFTs; `manuscript/analysis/23-gtdb-phylogeny.R`).
Three follow-ups read the unsupported calls:

- `29-gtdb-near-misses-and-gift-signal.R` counts near misses: unsupported GIFTs
  whose closest implementation has at least two requirements and lacks exactly
  one. There are 11,736 among 81,599 unsupported calls.
- `30-gtdb-near-miss-steps.R` asks which requirement is missing and whether the
  requirements present are specific to the GIFT. A requirement is *shared* when
  another GIFT requires the same reaction or function, or accepts one of its
  markers.
- `26-gtdb-repertoire-genome-size.R` identifies phyla that support fewer GIFTs
  than their genome size predicts, and repeats that on better-assembled subsets.

The tables are in `manuscript/analysis/output/`: `gtdb-near-miss-steps.tsv`
(one row per implementation and missing requirement, with its reading),
`gtdb-near-miss-implementations.tsv`, `gtdb-near-miss-requirements.tsv`,
`gtdb-size-expectation-sensitivity.tsv` and `gtdb-phylogeny-gift-summary.tsv`.

Three limits apply to every lead below.

1. **Only the closest implementation is read.** For a GIFT with several
   implementations the call table keeps one, so a near miss says which
   requirement that one lacks, not what the alternatives lack. Item 1 is the
   consequence.
2. **The sharing rule sees the database, not biology.** A marker that is
   biologically broad but accepted for one requirement only counts as specific.
   Item 2 is the consequence.
3. **A near miss cannot tell an uncurated alternative from a failing marker or
   from a capability that is not encoded.** The genes below the KOfam cut-off
   would separate the first two; they were not transferred from Mjolnir
   (item 9).

A near miss is never support. Nothing in this document licenses a call.

## Before acting on a lead

Search `catalogue-expansion-attempts.tsv` and
[the deferral register](deferral-register.md) for the GIFT and its aliases, and
read the linked source: the boundary or marker in question may have been chosen
deliberately. Attempts that curated the GIFTs named here include
`GEA-20260817-NUCLEOTIDE-BASELINE`, `GEA-20260818-SCFA`,
`GEA-20260818-VITAMINS`, `GEA-20260818-SUGAR-AND-POLYSACCHARIDE`,
`GEA-20260818-NITROGEN-CATABOLISM`, `GEA-20260819-AMINO-ACID-EXPANSION` and
`GEA-20260820-NEXT-RELEASE`. They were not re-read for this list, so
`revisits` is empty in the attempt row.

## To-do

### 1. Read near misses per implementation, not only the closest one

- [ ] Extend the near-miss analysis to every implementation of a GIFT.

`purine_core_biosynthesis` has eight routes, four of them through the two-step
N5-CAIR chemistry. Its 137 near misses are all reported against
`PCR_FOLATE_DIRECT_FOLATE` as lacking the direct AIR carboxylase (`RHEA:10792`;
`K01587`, `K11808`), with 9 of 10 reactions present. Those genomes therefore
also fail every two-step route, and the table does not say by how much. Until
this is done, a lead on a multi-implementation GIFT may point at the wrong
route. `trace_gift()` already returns every implementation.

### 2. Review the specificity of `K01426` in `indole_3_acetate_biosynthesis`

- [ ] Check whether `K01426` can stand as evidence for indole-3-acetamide
      hydrolase (`RHEA:34371`, component `COMP_34371_AMIDASE`).

`K01426` is a general amidase orthologue. 618 of 696 genomes satisfy the
hydrolase step and lack only tryptophan 2-monooxygenase (`RHEA:16165`,
`K00466`); 4 genomes support the GIFT. No false positive follows, because the
committing step is required as well, but a marker present in 89% of genomes
does not identify this substrate. Invariant 16 applies: a marker that cannot
distinguish one substrate from another licenses only the broader claim. The
alternative marker for the same reaction is `K21801`.

- [ ] Cross-check the other single-use markers of two-requirement GIFTs against
      [the specificity screen](proposal-marker-specificity-screen.md), since the
      sharing rule cannot flag them.

### 3. Assess a missing alternative for a single step of a long pathway

These are the strongest leads: at least two GIFT-specific requirements are
present, and the same one is missing in at least 90% of the implementation's
near misses. Each needs the check in item 1 first where the GIFT has several
implementations.

| Done | GIFT, implementation | Requirement always missing | Markers curated for it | Genomes one step short | Specific steps present | Genomes supporting the GIFT | Phylum most affected |
|---|---|---|---|---|---|---|---|
| [ ] | `histidine_degradation_glutamate`, `HUT_FORMAMIDE` | `RHEA:22492` formimidoylglutamase | `K01479` | 183 | 3 of 3 | 86 | Deinococcota (83%) |
| [ ] | `cobamide_nucleotide_loop_assembly`, `LOOP_DMB` | `RHEA:24456` alpha-ribazole phosphatase | `K02226`, `K22316` | 157 | 3 of 3 | 110 | Desulfobacterota (67%) |
| [ ] | `dap_biosynthesis`, `DAP_AMINOTRANSFERASE` | `RHEA:23988` LL-diaminopimelate aminotransferase | `K10206` | 147 | 3 of 3 | 390 | Campylobacterota (100%) |
| [ ] | `assimilatory_sulfate_reduction`, `SULFATE_APS_FD` | `RHEA:23132` ferredoxin sulfite reductase | `K00392` | 143 | 2 of 2 | 168 | Deinococcota (67%) |
| [ ] | `purine_core_biosynthesis`, `PCR_FOLATE_DIRECT_FOLATE` | `RHEA:10792` AIR carboxylase | `K01587`, `K11808` | 137 | 8 of 9 | 407 | Campylobacterota (67%) |
| [ ] | `butyrate_formation`, `BUTYRATE_ACOA_TRANSFERASE` | `RHEA:30071` butanoyl-CoA:acetate CoA-transferase | `TIGR03948` | 111 | 3 of 4 | 4 | Bacteroidota (65%) |
| [ ] | `biotin_biosynthesis`, `BIOTIN_SAM` | `RHEA:20712` 8-amino-7-oxononanoate synthase | `K00652` | 103 | 3 of 3 | 192 | Campylobacterota (89%) |
| [ ] | `rhamnose_degradation`, `RHA_ISOMERASE` | `RHEA:19689` rhamnulose-1-phosphate aldolase | `K01629` | 69 | 2 of 2 | 32 | Deinococcota (67%) |

For each: is there a known non-homologous or lineage-specific enzyme for that
reaction, and is it a second system of the same reaction (the enzyme-system
layer) or a second route (the route layer)? `butyrate_formation` is the most
suspicious: one TIGRFAM profile carries the terminal step, 4 genomes in the
panel support the GIFT, and 111 have the rest of the route.

### 4. Re-read two-requirement GIFTs where the same half is always missing

One specific requirement is present and the other is missing in at least 85% of
near misses. With a single requirement present the evidence is thin, so these
rank below item 3. `IAA_IAM` (item 2) is the same pattern and shows how it can
mislead.

| Done | GIFT | Requirement missing | Genomes one step short | Genomes supporting the GIFT |
|---|---|---|---|---|
| [ ] | `chitin_degradation` | `RXN_CHITIN_ENDO` endochitinase (GH18 family markers) | 331 | 144 |
| [ ] | `methionine_biosynthesis_transsulfuration` (4 requirements, 1 specific present) | `RHEA:30931` cystathionine gamma-synthase, O-acetylhomoserine (`K01739`) | 282 | 35 |
| [ ] | `nad_biosynthesis_namn` | `RHEA:24384` glutamine-hydrolysing NAD synthetase (`K01950`) | 267 | 327 |
| [ ] | `methylglyoxal_detoxification` | `DF_MG_GLYOXALASE_I` (`K01759`) | 237 | 252 |
| [ ] | `creatinine_degradation` | `RHEA:22456` creatinase (`K08688`) | 231 | 16 |
| [ ] | `starch_degradation` | `RXN_STARCH_ENDO_1_4` alpha-amylase (GH13 family markers) | 203 | 157 |
| [ ] | `type_i_e_crispr_cas_machinery` | `DF_CRISPR_I_E_SURVEILLANCE` | 174 | 38 |
| [ ] | `phosphate_starvation_response` | `RF_PHO_RESPONSE_PHOB` (`K07657`) | 160 | 226 |
| [ ] | `acetate_interconversion` | `RHEA:19521` phosphate acetyltransferase | 135 | 302 |
| [ ] | `fumarate_oxaloacetate_interconversion` | `RHEA:21432` malate dehydrogenase | 132 | 416 |
| [ ] | `glucuronate_degradation` (3 requirements) | `RHEA:15729` fructuronate reductase (`K00040`) | 125 | 25 |
| [ ] | `threonine_biosynthesis` | `RHEA:13985` homoserine kinase | 121 | 446 |
| [ ] | `aspartate_semialdehyde_biosynthesis` | `RHEA:23776` aspartate kinase | 103 | 516 |
| [ ] | `oxoglutarate_to_succinate` | `RHEA:17661` succinyl-CoA synthetase | 102 | 402 |
| [ ] | `urate_degradation` | `RHEA:27329` FAD-dependent urate hydroxylase (`K16839`) | 98 | 54 |

Two readings to test first: the missing requirement has a known alternative
enzyme (NH3-dependent NAD synthetase for `K01950`; other malate dehydrogenase
and urate oxidase families), or the present requirement is the broad one, as in
item 2.

### 5. Leave the correct refusals alone, and check two boundaries they expose

In 2,724 near misses every requirement present is shared with another GIFT, so
the missing GIFT-specific requirement is the completeness model doing its job.
No action on the calls. The most frequent are
`oxobutanoate_biosynthesis_citramalate` lacking citramalate synthase
(`RHEA:19045`, 475 genomes; the other three reactions are the leucine
enzymes), `xylan_degradation` lacking `RXN_XYLAN_ENDO_1_4` (315),
`thiamine_precursor_salvage` lacking `RHEA:24212` (189) and
`siroheme_biosynthesis` lacking `RHEA:24360` (154).

- [ ] `aspartate_chemoreception` and `serine_chemoreception` are each supported
      in 5 of 696 genomes and one step short in 244, lacking only the receptor.
      Confirm that so narrow a prevalence is the intended consequence of
      requiring a receptor-specific marker.
- [ ] `xylan_degradation`: its present requirement is satisfied entirely by
      markers shared with other GIFTs. Confirm the non-endo requirement is as
      substrate-specific as the GIFT's name.

### 6. Check GIFTs that almost no genome supports

A GIFT supported by none or a handful of 696 phylogenetically broad genomes is
either genuinely rare or defined too narrowly.

- [ ] Supported in no genome: `propionate_formation_propanediol`,
      `carnitine_degradation_trimethylamine`, `phenylacetate_degradation`.
      (`archaellum` is also unsupported, as expected in a bacterial panel.)
- [ ] Supported in one to five genomes: `propionate_formation_acrylate` (1),
      `dihydroxyphenylpropanoate_degradation` (2), `oxoadipyl_coa_thiolysis`
      (2), `citrate_fermentation` (2), `fucose_degradation_isomerase` (2),
      `neuac_degradation` (2), `ribitol_phosphate_wall_teichoic_acid` (2),
      `phenylpropanoate_dihydroxylation` (3),
      `diglucosyl_diacylglycerol_anchored_lipoteichoic_acid` (3),
      `type_iii_secretion_injectisome` (3), `butyrate_formation` (4),
      `indole_3_acetate_biosynthesis` (4), `pectate_lyase_degradation` (4).

For each, name a panel genome expected to carry the capability from the
literature and trace why it fails, or record that the panel holds no such
organism. Prevalence in the wider frame was already a gate for several of these
(section 2 of the deferral register), so read those rows first.

### 7. Review catalogue coverage for lineages below the size expectation

Six phyla support fewer GIFTs than their genome size predicts under every
quality variant in which they can be tested: Spirochaetota (median −11.8 GIFTs),
Bacillota_I (−6.9), Cyanobacteriota (−6.8), Planctomycetota (−6.7),
Bacteroidota (−5.7) and Patescibacteriota (−4.6). Chloroflexota and
Acidobacteriota are below expectation only before assembly quality is
accounted for.

- [ ] For Spirochaetota, Cyanobacteriota, Planctomycetota and Bacteroidota,
      list the requirements most often missing alone
      (`gtdb-near-miss-requirements.tsv`) and ask whether the lineage is known
      to use a different enzyme. Bacteroidota is 65% one step short on
      `butyrate_formation`.
- [ ] Patescibacteriota and Bacillota_I have few near misses (medians 3 and
      5.5), so their low repertoires are not a matter of single missing steps.
      No curation follows from this panel; record that if asked again.

A deficit may equally mean that the lineage's metabolism lies outside what the
catalogue has curated at all, which no near miss can show.

### 8. Do not act on the scattered near misses

In 3,445 near misses the missing requirement varies between genomes of the same
implementation. There is no single target, and no to-do.

### 9. Collect the evidence that separates an alternative from a failing marker

- [ ] For the requirements in items 3 and 4, read the raw KOfam hits of the
      near-miss genomes on Mjolnir
      (`projects/gifter-gtdb-phylogeny/tasks/02-drakkar-annotation/output/annotating/kegg/`,
      reported at E ≤ 10) and count genomes with a hit to the missing KO below
      its model cut-off. Many sub-threshold hits point to a marker that fails
      in that lineage; none points to a different enzyme or a real absence.
- [ ] Make the sharing rule of `30-gtdb-near-miss-steps.R` consult the marker
      specificity grades, so that a broad single-use marker is not counted as
      specific.

## What this list does not claim

It does not claim that any genome encodes a capability it was called
unsupported for, that any listed marker is wrong, or that a named alternative
exists in a named lineage. The biological suggestions in items 3 and 4 were not
checked against the literature. Closing an item means either a curated change
with its own `database_changes.tsv` entry, or a recorded refusal in a proposal
and, while it stands, a row in the deferral register.

## Sources

- `manuscript/analysis/26-gtdb-repertoire-genome-size.R`,
  `manuscript/analysis/29-gtdb-near-misses-and-gift-signal.R`,
  `manuscript/analysis/30-gtdb-near-miss-steps.R`
- `manuscript/analysis/output/gtdb-near-miss-steps.tsv`,
  `gtdb-near-miss-implementations.tsv`, `gtdb-near-miss-requirements.tsv`,
  `gtdb-near-miss-readings.tsv`, `gtdb-size-expectation-sensitivity.tsv`,
  `gtdb-phylogeny-gift-summary.tsv`
- `manuscript/analysis/gtdb-phylogeny/README.md` for the panel
