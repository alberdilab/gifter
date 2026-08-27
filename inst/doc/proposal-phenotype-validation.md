# Phenotype references as an external validation layer

Status: **assessment, and now partly executed.** It answers manuscript open
decision 1 — the phenotype reference set for R9 — with a recommendation, and it
refuses two of the three resources the question named. Sections 4 to 6 have
since been run: `manuscript/analysis/03-phenotype.R` and `04-auxotrophy.R`
produce the tables, and §5 has been **corrected against what running it found**.
Where an estimate in this document has been superseded by a measurement, the
measurement is given and the estimate is struck rather than quietly replaced.

The question put to this assessment: can gifter be validated or benchmarked
against FAPROTAX, BacDive, the Madin *et al.* trait synthesis, or other
genome–phenotype information?

The short answer is yes, for about a seventh of the catalogue at the level of an
individual call and about a third more only in aggregate, and only if the
benchmark abandons accuracy as its statistic. Invariant 15 says a positive call
is not a claim about phenotype. That is not a caveat to be apologised for in a
validation section — it *determines the design*, because it makes the two
directions of disagreement mean different things, and only one of them is a
result about gifter.

The resource the question named first, FAPROTAX, is the one to refuse. The
resource it did not name, MediaDive, is the only one that reaches the anabolic
half of the catalogue, and it reaches it in the falsifying direction.

---

## 1. Decisions

| Resource | Role | Verdict | Why |
|---|---|---|---|
| **BacDive** | Primary reference | **adopt** | Strain-resolved measured phenotype, 50 588 linked genome assemblies, explicit `+`/`-`/`+/-`, and three joins onto identifiers gifter already holds: ChEBI metabolites, EC activities, INSDC assemblies. CC BY 4.0, no registration. §4 |
| **MediaDive defined media** | Anabolic reference | **adopt** | 662 chemically defined media with per-ingredient composition and strain links. The only resource that tests the 44 GIFTs of the four bounded frames, and the only one where a gifter *number* is falsifiable. §5 |
| **Madin *et al.* trait synthesis** | Secondary, narrow | **adopt for two axes only** | Motility (2 118 species with a genome-backed match) and 108 carbon-substrate terms. Its `pathways` column is FAPROTAX re-served and must be dropped before use. §6 |
| **FAPROTAX** | Ground truth | **refuse** | It is a taxonomy-propagated predictor, not an observation, and its discriminating categories are overwhelmingly the electron-acceptor class gifter refuses by architecture. It may appear in R8 as a *comparator*, never in R9 as a reference. §3 |
| **ProTraits** | Ground truth | **refuse** | Text-mined and partly genome-derived. Benchmarking a genome-based caller against genome-derived labels measures agreement between two predictors. §7.4 |
| **BacDive's `Genome-based predictions` section** | Any role | **refuse** | Prediction, not observation. It is inside the resource being adopted, which is exactly why it needs an explicit exclusion. §4.4 |

Two things must **not** be built. There must be no phenotype table in the
compiled database: the database states what gifter claims, and an observation
about a strain is not a claim gifter makes. And there must be no accuracy,
precision, F1, MCC or AUC anywhere in R9 — §2 explains why each of them encodes
an assumption the model denies.

## 2. What a phenotype benchmark is allowed to claim

A GIFT call says a genome carries evidence for at least one complete known
implementation of a capability. Under invariant 15 that is a **necessary, not
sufficient** condition for the corresponding phenotype. Expression, regulation,
uptake, assay conditions and the medium all sit between the call and the
observation, and gifter models none of them.

So the two disagreements are not symmetric, and a benchmark that averages them
into one number destroys the only information it had.

| | Observed **positive** | Observed **negative** |
|---|---|---|
| **Call supported** | Concordant | **Permitted.** Silence, regulation, missing transport, wrong assay condition. Not an error, and counting it as a false positive asserts a claim gifter refuses to make |
| **Call unsupported** | **Failure.** A missing route, a missing marker, a boundary drawn too narrowly, an annotation miss, or a strain–genome mismatch | Concordant |

Only the bottom-left cell is a result *about gifter*, and the statistic that
reads it is **recall of the call against the observed positive phenotype**.
Everything above the diagonal on the right is a rate to report, characterise and
explain, never to penalise.

**Auxotrophy would invert the polarity — but no adopted source records it.**
The argument was this: for an anabolic GIFT the observation is the *absence* of
a requirement, so a genome called *supported* whose strain cannot grow without
the nutrient is a demonstrable over-call, and anabolic capabilities would be the
one place in the catalogue where an observation falsifies a *positive* call.

That argument is sound and the data do not support it. Every MediaDive
medium–strain row carries `growth = 1`: the resource records the media a strain
grows on and nothing else. There is no observed auxotrophy in it, only observed
prototrophy, so the falsifiable cell remains the unsupported call exactly as in
the catabolic half. §5 is corrected accordingly, and the missing piece — a
defined-medium dropout panel, in which a strain is recorded as *failing* to grow
without a nutrient — is filed in the register.

What the anabolic half buys instead is **leverage**, not polarity: a single
growth observation on a mineral medium tests every nutrient that medium omits at
once, which is how 171 strain–medium pairs became 3 644 nutrient-level tests.

Three consequences for the design:

1. Report **per-GIFT counts, not pooled rates**. A pooled recall over a
   catalogue whose GIFTs have wildly different testability is a number about the
   test set, not about gifter.
2. Report the **taxonomic composition beside every count**. Phenotype records
   are clustered in *Enterobacteriaceae*, lactobacilli and clinical taxa; a
   binomial confidence interval over them assumes an independence that does not
   exist. This is the same discipline `dataset_traits()` already applies when it
   prints the detected genome count beside a richness.
3. Every disagreement carries gifter's own trace. `minimum_missing_requirements`
   and `missing_reactions_best_route` name the step that failed, so the
   classification of the failure set is mechanical rather than anecdotal. That
   is a selling point of the abstraction, and R9 should be written as a
   classification of disagreements with a recall table attached — not the
   reverse.

## 3. FAPROTAX is not a reference, and the numbers say why

Two independent reasons, either sufficient.

**It is a predictor.** FAPROTAX assigns a function to an OTU by matching its
taxonomic name against a literature-derived name→function table built from
cultured representatives. The label attached to a genome is therefore a
*propagation from that genome's taxonomy*, not an observation of that genome's
organism. Benchmarking a genome-based caller against a taxonomy-based caller
measures phylogenetic conservation of the capability, and the direction of a
disagreement is uninterpretable: gifter may be wrong, FAPROTAX may have
propagated across a lineage where the trait is not conserved, and nothing in the
comparison distinguishes them. This is the same objection that closed CARD as a
runtime namespace — the organising axis is not the axis gifter reasons on.

**Its vocabulary is the vocabulary gifter refuses.** Of the 103 distinct pathway
terms reaching the Madin synthesis, the most frequent are `nitrate_reduction`
(3 194 records), `fermentation` (2 545), `aerobic_chemo_heterotrophy` (1 000),
`denitrification` (671 plus 484 under a capitalised duplicate),
`nitrite_reduction` (641), `sulfate_reduction` (496), `iron_reduction` (454) and
`methanogenesis` (415). Every one of those is either the electron-acceptor class
the register refuses outright, or a superset so broad that no relation but
`overlaps` could be recorded — gifter's `fermentation_products` frame holds 11
GIFTs, and `fermentation` is equivalent to none of them.

What survives is thin: `xylan_degradation` (375), `cellulose_degradation` (377,
and gifter curates no cellulose capability), `chitin_degradation` (136) and
`urea_degradation` (68). Four terms, two of which BacDive measures directly and
better.

A benchmark against FAPROTAX would therefore score gifter as absent across most
of FAPROTAX's discriminating categories — not because the calls are wrong, but
because the claims were declined on the record. Publishing that table would
misrepresent a documented architectural boundary as a coverage failure.

FAPROTAX has a legitimate place in **R8**, beside KEGG module completeness, DRAM
and METABOLIC, as one more abstraction to compare against. That section already
says it is a comparison of abstractions and not a benchmark with a winner, which
is exactly the right frame for it.

## 4. BacDive is the reference the design needs

Probed 2026-08-23 against the v2 REST API. Registration was dropped in February
2026; results are CC BY 4.0; the database passed 100 000 strains in the 2025
release and now links **50 588 genome assemblies**.

### 4.1 It joins onto identifiers gifter already holds

| BacDive field | Content | Joins to | gifter layer tested |
|---|---|---|---|
| `metabolite utilization` | ChEBI ID, metabolite, activity `+`/`-`/`+/-`, and `kind of utilization tested` | Declared anchors (152 of 156 carry a ChEBI ID) | The **GIFT call** |
| `metabolite production` | ChEBI ID, produced yes/no | Output anchors | The **GIFT call** |
| `enzymes` | Activity name, `+`/`-`, **EC number** | `reaction_xrefs` (417 distinct EC accessions over 439 reactions) | The **reaction and system layers** |
| `Sequence information → Genome sequences` | INSDC `GCA_` accession, NCBI tax ID, assembly level, score | The genome under evaluation | The join itself |
| `Morphology → cell morphology` | `motility`, gram stain, cell shape | `flagellar_apparatus` | The **structural** model |

That the enzyme table is EC-resolved matters more than it looks. It tests a
different layer: an observed β-N-acetylhexosaminidase activity is evidence about
the *component* inference, not about route completeness, and it needs no
phenotype caveat at all. `tryptophan_degradation_indole` is the demonstration
case — BacDive records both tryptophanase activity (EC 4.1.99.1) and indole
production for the same strains, so one GIFT is testable at two layers against
two independent observations. That figure belongs in the paper.

### 4.2 How much of it is usable

A random sample of 400 BacDive IDs drawn from 1–180 000 returned 227 valid
records, implying about 102 000 strains in the identifier space:

| Has | Records | Share |
|---|---|---|
| A linked genome | 38 | 17% |
| Metabolite utilisation or production | 70 | 31% |
| Enzyme activities | 65 | 29% |
| **A genome *and* phenotype data** | **22** | **9.7%** |
| A genome and a motility call | 16 | 7.0% |

Projected over the database, that is on the order of **10 000 genome-backed
phenotyped strains** and **7 000 with a genome-backed motility call**. Per
substrate the sample gives 13 genome-backed records for L-arabinose, 12 for
urea, 11 for N-acetylglucosamine, 9 for glycogen, 9 for citrate and 6 for
L-rhamnose out of 227 — an order of 10³ strains per substrate once projected,
one to two orders of magnitude beyond what the Madin route in §6 can supply.

Those are sampled rates, and the sampling is an artefact of the probe rather
than of the plan: `/v2/fetch/` accepts **100 semicolon-separated IDs per
request**, so a complete sweep of BacDive costs roughly 1 100 requests. R9
should ingest the whole database and select on the data, not sample it. The
reverse join is also available — `/v2/sequence_genome/{INSDC}` resolves an
assembly accession straight to its strain, which is the cheaper direction when
the genome set is fixed in advance.

`kind of utilization tested` is not optional metadata; it is part of the claim.
The sample's distribution — `builds acid from` 1 006 records, `assimilation`
268, `hydrolysis` 209, `fermentation` 140, `carbon source` 122 — shows that most
records are API-panel acidification, which is a fermentation observation and
only `subset_of` "degrades this substrate". A crosswalk that ignores the column
silently promotes an acid-production test into a catabolic-route claim.
`respiration`, at 102 records, is the electron-acceptor class and is dropped
whole.

### 4.3 Nine enzyme activities already land on curated reactions

Of the thirty most frequent EC-resolved activities in the sample, nine
correspond to reactions gifter curates:

| EC | Activity | GIFT | Records | Of those, genome-backed |
|---|---|---|---|---|
| 3.5.1.5 | Urease | `urea_hydrolysis` | 71 | 20 |
| 3.2.1.52 | β-N-acetylhexosaminidase | `chitin_degradation` | 50 | 12 |
| 3.2.1.20 | α-glucosidase | `starch_degradation` | 45 | 13 |
| 3.5.3.6 | Arginine deiminase | `arginine_deiminase_pathway` | 43 | 9 |
| 3.2.1.51 | α-L-fucosidase | `mucin_fucose_release` | 33 | 10 |
| 4.1.99.1 | Tryptophanase | `tryptophan_degradation_indole` | 16 | 5 |
| 1.1.1.1 | Alcohol dehydrogenase | `ethanol_formation` | 13 | 4 |
| 3.2.1.55 | α-L-arabinofuranosidase | `arabinoxylan_debranching` | 5 | 3 |
| 4.1.1.15 | Glutamate decarboxylase | `glutamate_decarboxylation_gaba` | 5 | 3 |

Thirty further EC-resolved activities in the sample reach no curated reaction —
β-galactosidase, β-glucosidase, β-glucuronidase, the aminopeptidases, catalase
and cytochrome oxidase among them. Most name chemistry gifter has no GIFT for;
two, the oxidase and the nitrate reductase, name the refused axis.

Endo-1,4-β-xylanase (3.2.1.8), chitinase (3.2.1.14) and sialidase (3.2.1.18)
also map to curated reactions but did not appear in this sample, so their
frequency is unmeasured rather than zero.

Metabolite production is the other high-yield field: indole in 57 of 227
records, acetoin in 17, hydrogen sulfide in 13 — reaching
`tryptophan_degradation_indole`, `acetoin_formation` and
`cysteine_degradation_sulfide`.

### 4.4 What must be excluded, and one join that is not free

BacDive now ships a `Genome-based predictions` section and a genome browser.
Anything in it is a prediction and must be dropped at ingestion; a reference set
that quietly includes another tool's genome inferences would turn R9 into a
tool-comparison with the wrong label on it.

The metabolite join is **not** plain ChEBI equality, and it fails in a pattern.
Of 196 distinct metabolite ChEBI identifiers in the sample, 21 matched an anchor
outright — and they are almost all polymers, carboxylates and amino sugars:
`ARABINOXYLAN`, `CHITIN`, `STARCH`, `XYLAN`, `ACETATE`, `BUTYRATE`,
`PROPIONATE`, `LACTATE_L`, `CITRATE`, `SUCCINATE`, `PHENYLACETATE`, `GLCNAC`,
`GALNAC`, `UREA`, `NITRATE` and five amino acids.

**Every free sugar misses, by exactly one ChEBI step.** BacDive records
L-arabinose as `CHEBI:30849` where the anchor is `CHEBI:17535`; L-rhamnose as
`CHEBI:62345` against `CHEBI:62346` L-rhamnopyranose; D-xylose as `CHEBI:65327`
against `CHEBI:53455`; D-galactose as `CHEBI:12936` against `CHEBI:27667`
beta-D-galactose; L-fucose as `CHEBI:18287` against `CHEBI:2181`. The anchors
are anomeric and charge-resolved because Rhea's participants are, and the assay
records the parent. Since the sugars are the highest-value substrate tests, this
one-step gap is not a detail.

The bridge is ChEBI's own conjugate-acid/base and parent relations, which is a
small, one-off, *curated* job — and it must be curated rather than traversed
automatically, because a walk that goes one step too far turns a specific anchor
into a compound class, which is invariant 16 breached through the back door.

## 5. MediaDive reaches the anabolic half

Nothing in FAPROTAX, and nothing in the Madin substrate columns, says anything
about the 67 anabolic GIFTs — 44% of the catalogue. Growth media do.

**This section has been run, and three of its claims did not survive.** They are
corrected below rather than deleted, because each was wrong in a way worth
recording.

MediaDive is open, unauthenticated, and holds **3 339 media, of which 662 are
chemically defined**, each with a per-ingredient composition (name, g/l, mmol/l,
`optional`) and strain links carrying a `growth` flag and a `bacdive_id`.

The reasoning is simple and strong. A strain that grows on a defined medium
containing no L-tryptophan synthesises L-tryptophan. One such observation
therefore tests every anabolic GIFT whose product the medium omits — in
practice, for a mineral medium, all 44 members of `biomass_essential_anabolism`
at once (22 amino acid, 15 cofactor, 4 nucleotide, 3 inorganic nitrogen). Where
the medium *does* supply a nutrient — a vitamin solution, casamino acids, yeast
extract — the test for those GIFTs is **void**, not negative, and the ingredient
list says which. That per-nutrient denominator is exactly the discipline the
frame layer already enforces, which is what makes this the natural fit.

It is also the only design in this document that validates a **number**. The
four bounded frames — `biomass_essential_anabolism`, `amino_acid_autonomy`,
`nucleotide_autonomy`, `cofactor_autonomy` — are declared `bounded`, a claim
that curation intends to cover the set completely, and a proportion is only
emitted against them for that reason. A strain growing on a mineral medium
should score 1.0 on `amino_acid_autonomy`. Every point below 1.0 is a named,
traceable, falsified anabolic call. R4 currently has no external check of any
kind; this is one.

### 5.1 What running it changed

**The estimate of *n* was close.** 646 of the 662 defined media returned a
composition, and they yield **1 748 growth-positive strain–medium pairs** over
1 594 strains, against the 1 400 projected from a twelve-medium sample. Of those
pairs, **270 reach a genome in the reference set**, covering 225 genomes, and
264 of them sit on a medium at least three-quarters readable — the attrition is
the genome link, not the media. Ingredient resolution is not the problem the
assessment feared: median 0.97 of a defined medium's ingredients carry a ChEBI
identifier.

*(The 171 pairs over 129 genomes this section first reported came from a smaller
BacDive sweep than the catabolic half was run on. Re-running `04-auxotrophy.R`
against the sweep of 2026-08-27 puts both halves of R9 on one reference set,
which is §9's rule applied to our own tables rather than to the literature.
Every figure below is from that run; the ones it moved are noted where they
changed.)*

**Correction 1: the premise holds only for nutrients the organism requires.**
"Grows without X, therefore makes X" is valid only where X is biomass-essential.
Amino acids and nucleotides are, in every bacterium. Menaquinone is not — plenty
of lineages use ubiquinone instead — and neither siroheme nor DMB is universal.
Nitrogen fixation is worse than non-essential: an organism handed ammonium has
no reason to fix N₂ at all, so demanding it is simply a wrong question. Scoring
those classes gives `MENAQUINONE` 0.091 and `AMMONIUM` 0.508, and neither number
is about gifter. The analysis reports every class and restricts the headline to
the essential ones.

**Correction 2: the frame contains alternative routes, and they must be OR-ed.**
`cysteine_biosynthesis_homocysteine` and `cysteine_biosynthesis_sulfide` are two
implementations of one requirement and an organism needs either; the same holds
for the two methionine routes, the two PLP routes and NAMN. Testing members
individually scores whichever route an organism does not use as a failure.
Grouping frame members by their **output anchor** and OR-ing them is the same
Boolean the evaluator applies one layer down, and it moved recall from 0.658 to
0.722 on its own.

**Correction 3: GIFTs no KO can evidence must be excluded.** `siroheme_to_heme_b`
scored 0.000 because its evidence is NCBIfam and the reference genome set is
KEGG's KO assignment. That is a property of the genome set, not a failed call,
and §7.2's upper-bound caveat applies here with force.

### 5.2 The result

264 strain–medium pairs over 201 genomes yield 9 050 nutrient-level tests. With
the premise restricted to biomass-essential classes and alternatives OR-ed:
**5 803 nutrient-level tests over 201 genomes, recall 0.844**.

| Frame | Median proportion supported | Genomes scoring 1.0 |
|---|---|---|
| `nucleotide_autonomy` | **1.000** | 170 of 201 |
| `amino_acid_autonomy` | 0.850 | 7 of 201 |
| `cofactor_autonomy` | 0.500 | 0 of 200 |

The nucleotide row is the clean one, and it is the first external check R4 has
ever had: 170 of 201 genomes score a full 1.0 on a bounded frame, on strains
observed to grow on media supplying none of it.

`SERINE` at 0.302 and `HISTIDINE` at 0.574 are the rows worth curating against.
Both are biomass-essential, neither has an alternative curated route to merge,
and the premise is sound for both — so those are gifter's, and they are named in
`auxotrophy-disagreements.tsv` with the genome behind every one.

**What the enlarged sweep did and did not move.** Recall fell 0.849 → 0.844 and
every per-nutrient row moved by less than 0.07, in both directions:
`HISTIDINE` 0.520 → 0.574 and `GLUTAMATE` 0.757 → 0.818 rose, `TRYPTOPHAN`
0.961 → 0.897 and `TYROSINE` 0.757 → 0.707 fell. That stability across a 59%
larger test set is worth more than the headline: it says the anabolic figure is
a property of the catalogue rather than of which strains happened to be in the
sweep. The 39 scored rows are unchanged in identity — no nutrient entered or
left the table.

## 6. What survives from the Madin synthesis

172 324 records over 21 500 species, one file, NCBI tax IDs, immediately
usable. Two axes are worth taking and the rest is not.

**Drop `pathways` entirely.** 9 515 of its 15 996 records come from FAPROTAX and
carry §3's problems unchanged.

**Take `motility`.** 22 765 records over 7 524 species, valued `no` (12 159),
`yes` (9 281), `flagella` (1 146), `gliding` (170). Both directions, at a scale
nothing else offers, for `flagellar_apparatus` — the structural model's only
realistic external check. The asymmetry of §2 applies with force here: an
organism observed to swim must encode a flagellum, while an organism recorded
non-motile may simply not have been seen to move.

**Take `carbon_substrates` with eyes open.** 108 terms over 4 151 species,
sourced from Fierer's compilation and a methanogen set — and, unlike BacDive, it
records only substrates that *were* used. No negatives. Under §2 that costs
nothing, because observed-positive is the informative direction anyway.

Joining KEGG's 11 949 genome entries (8 750 distinct binomials) to Madin's
bacteria and archaea gives **3 738 shared species covering 6 377 KEGG genomes**.
Within that intersection:

| Madin substrate | Species | GIFT | Relation |
|---|---|---|---|
| arabinose | 216 | `arabinose_degradation` | equivalent |
| galactose | 194 | `galactose_degradation_leloir` | equivalent |
| xylose | 150 | `xylose_degradation_isomerase` | equivalent |
| N-acetylglucosamine | 129 | `glcnac_degradation` | equivalent |
| citrate | 110 | `citrate_fermentation` | subset_of |
| rhamnose | 99 | `rhamnose_degradation` | equivalent |
| glycogen / dextrin | 70 / 57 | `starch_degradation` | overlaps |
| fucose | 52 | `fucose_degradation_isomerase` | equivalent |
| histidine | 38 | `histidine_degradation_glutamate` | overlaps |
| phenylacetate | 31 | `phenylacetate_degradation` | equivalent |
| galacturonic acid | 19 | `galacturonate_degradation` | equivalent |
| trimethylamine / methylamine | 17 / 17 | `methylamine_degradation` | subset_of |
| urea | 13 | `urea_hydrolysis` | equivalent |

Motility in the same intersection reaches 2 118 species.

**The most-measured substrates are the ones gifter does not curate**, and that
is worth recording as a finding rather than as an embarrassment. Counted the
same way as the table above — species with a KEGG genome behind them — glucose
reaches 364, maltose 275, lactose 244, sucrose 227, mannitol 183, trehalose 169
and cellobiose 165. Every one of them outranks arabinose, the best-covered
substrate gifter can actually be tested on, and none has a GIFT. The
phenotype record is a prevalence signal of a kind the register does not yet
use — not what is *present* in genomes, but what the field bothered to measure —
and it names the candidates whose absence from the catalogue costs the most
external testability. That is a curation prioritisation input, and §9 files it.

## 7. Three joins, three confounds

### 7.1 Record → genome

Solved by BacDive's own assembly accessions, unsolved for Madin (species-level,
so a representative genome must be chosen and the within-species variation in
substrate use is absorbed silently). Restrict to complete or near-complete
assemblies using BacDive's `assembly level` and `score`, or R9 becomes a noisy
re-run of R7.

### 7.2 Genome → markers, the confound that decides what R9 measures

gifter consumes markers, not sequences, so a phenotype benchmark measures
gifter *composed with an annotator*. Two routes, and the recommendation is to
run both:

**The KEGG route, which is nearly free.** Prevalence screens already use KEGG's
11 949 genome entries, and one `link/genes/ko:<KO>` request per curated KO
marker — 750 requests — yields the complete KO × genome presence matrix without
running an annotator at all. **150 of 153 GIFTs have at least one complete
implementation reachable from KO markers alone** (the exceptions are
`assimilatory_sulfate_reduction`, `butyrate_formation` and `siroheme_to_heme_b`),
so the catalogue is almost fully reachable this way. The cost is that KEGG's
curated per-genome assignment is not what a user's KofamScan run produces: this
route measures gifter over an idealised annotation and must be reported as an
upper bound. It also under-calls every route whose only evidence is CAZy or
NCBIfam.

**The annotation route.** Annotate a subset of BacDive's assemblies with the
pipeline a user would actually run, pinned and versioned. Run it on a few
hundred genomes that the KEGG route also covers, and the difference between the
two is a directly reportable number: *how much of gifter's apparent
recall is annotation, not model*. No competing paper reports that, and it costs
one extra run.

### 7.3 Phenotype term → GIFT

The crux, and the only part that is curation rather than engineering. It must be
a reviewed crosswalk with an explicit relation drawn from the vocabulary
`gift_xrefs` already uses — `equivalent`, `subset_of`, `superset_of`,
`overlaps`, `related` — because invariant 1's reasoning applies unchanged: never
record a link that implies an equivalence the boundaries do not support.

Only `equivalent` pairs enter the primary recall table. `subset_of` and
`overlaps` pairs are reported separately and never pooled. A term with no
defensible relation is dropped, and the drop is recorded.

**Where it lives.** `data-raw/reference/phenotype-crosswalk.tsv`, beside the
other evidence that is consulted during curation and never compiled, plus the
analysis in `manuscript/analysis/`. Not in `inst/extdata/database-source/`: a
crosswalk to somebody else's observation vocabulary is a benchmark artefact, not
a claim gifter makes, and the moment it compiles into SQLite it starts looking
like one.

### 7.4 Circularity

Check each candidate for genome-derived content before adopting it. ProTraits
fails on this ground alone. BacDive's `Genome-based predictions` section fails.
Madin's `genome_size`, `gc_content`, `coding_genes` and `rRNA16S_genes` columns
are genome-derived and irrelevant here anyway. The observational fields of
BacDive and MediaDive are clean: they predate and are independent of the marker
layer. The residual — that a handful of NCBIfam equivalogs took their function
assignment from characterised strains BacDive also records — is real and
negligible, and belongs in one sentence of M6.

## 8. Coverage arithmetic, stated plainly

Estimated before running, then measured. The estimate was optimistic by a
third, which is the usual direction.

| Reach | Estimated | **Measured** | Share |
|---|---|---|---|
| Individually testable, at n ≥ 20 | ~22 | **14** | 9% |
| Testable only as a bounded-frame aggregate (§5) | 44 | 44 | 29% |
| **No phenotype reference of any kind** | ~87 | **95** | **62%** |

The 14 are `urea_hydrolysis`, `tryptophan_degradation_indole`,
`acetoin_formation`, `arabinose_degradation`, `xylose_degradation_isomerase`,
`galactose_degradation_leloir`, `rhamnose_degradation`, `glcnac_degradation`,
`starch_degradation`, `chitin_degradation`, `arabinoxylan_debranching`,
`mucin_fucose_release`, `arginine_deiminase_pathway` and
`glutamate_decarboxylation_gaba` — six of them reached only through the
reaction layer, which is why that layer earns its place.

**Re-measured on the enlarged sweep of 2026-08-27, the row moved to 15 / 44 / 94.**
`fucose_degradation_isomerase` crossed n ≥ 20 (it now stands at n = 75), so the
individually testable share is 10% and the unreferenced share 61%. The §9
caution applies to this row as much as to a recall: it is a count over a
reference set that grows, and the committed `phenotype-agreement.tsv` is what
R9 quotes. Nothing about the catalogue changed; the reference did.

The 62% is not a gap to be closed by finding another database. It is the
aromatic catabolic layer, most amino-acid catabolism, the cofactor and
nucleotide interior, every anchor-to-anchor segment that is not a growth
substrate, all three regulatory GIFTs and all five defense GIFTs. Nobody has
measured those phenotypes at scale, and for the regulatory and defense types the
observation would not be a phenotype in the assay sense at all.

R9 must therefore be written as *validation where validation is possible*, with
this table in it. A reader who is told which 62% was untestable will trust the
14% far more than a reader given a single headline agreement rate.

## 9. Recommendation

Items 1 to 6 are done; the state of each is recorded rather than the intention.

1. **Done.** BacDive is the primary reference, MediaDive covers the anabolic
   half, Madin contributes motility and carbon substrates. FAPROTAX, ProTraits
   and BacDive's genome-based predictions are refused, with rows in the
   register.
2. **Done.** `03-phenotype.R` reports recall against observed-positive
   phenotype per target, with the taxonomic spread beside every count and the
   permitted cell labelled as permitted. `agreement()` computes no pooled
   accuracy and offers none to compute.
3. **Done.** `01-marker-matrix.R` builds the KO × genome matrix in 750 requests
   over 11 949 genomes — every one carrying an NCBI taxon and a GenBank
   assembly — and emits the reference genome set that R7 and R8 also need.
4. **Done.** `phenotype-crosswalk.tsv` holds 56 reviewed rows, 36 of them
   recall-usable, across three layers.
5. **Done, and harder than described.** `chebi_anchor_aliases.R` derives 144
   aliases from identity-preserving ChEBI relations and refuses to derive the
   anomeric step at all; 11 of those are curated by hand and 223 candidates
   await review. §4.4 has the reasoning.
6. **Done for the first three, and all three are now closed.**
   `phenotype-disagreements.tsv` and `auxotrophy-disagreements.tsv` hold the rows;
   [the curation leads](proposal-phenotype-curation-leads.md) reads
   `glcnac_degradation` (0.154), `SERINE` (0.296) and `HISTIDINE` (0.520) down to
   the reaction. Two are unblocked marker gains the NCBIfam screen had already
   listed, and two are architectural decisions. All four have register rows.
   This is the layer paying for itself: a benchmark that found an under-call, a
   screen that had already listed the fix, and a taxonomy that explains both.
   `HISTIDINE` was curated in database 2026.25.1; `glcnac_degradation` was decided
   and curated in 2026.26.1, where a second route through the PTS raised recall
   from 0.128 to 0.205 on a matched test set; and `SERINE` was decided in
   2026.27.1, where the lead's premise did not survive the measurement and no
   second route was curated. Two leads, two decisions, opposite conclusions.

   **A caution about these figures, learned the hard way.** The catabolic half
   was re-run on 2026-08-27 against a BacDive sweep that had grown since the
   numbers above were recorded, and the test set moved from n = 119 to n = 229
   for `glcnac_degradation` alone. A recall figure here is only comparable to
   another one measured on the same sweep. Before quoting a before-and-after,
   rescore the earlier database against the current reference rather than
   comparing two runs — the cached calls make that cheap, and the enlarged sweep
   turned out to be the harder test set of the two. The auxotrophy figures were
   left untouched by that run, which is item 9.

Done since:

7. **The annotation route of §7.2 is run, and the bound is 9.4%.**
   `05-annotation-route.R` scores 398 matched genomes three ways — KEGG's
   per-genome KO assignment, KofamScan on the deposited proteins of the same
   assemblies, and that run plus the NCBIfam, dbCAN and Pfam namespaces the KEGG
   route cannot reach — with every cutoff the published one for its pipeline.
   Against 21,771 complete calls on the KEGG route, KofamScan alone returns
   19,735 (90.6%) and the whole pipeline 20,955 (96.3%).

   **The two steps have opposite signs and must not be pooled.** The annotation
   cost falls on long biosynthetic routes, where losing one marker loses the
   call: pyrimidine core biosynthesis 350 genomes to 162, NAD biosynthesis 336 to
   209. The recovery falls on carbohydrate chemistry, where CAZy is the evidence
   and orthology never was: `arabinoxylan_debranching` 42 to 322,
   `starch_degradation` 61 to 302. Six GIFTs the KEGG route calls in no genome at
   all are called on the annotation route, `mucin_galnac_release` in 222 of 398.
   Across the catalogue 47 GIFTs come out ahead of the KEGG route and 82 behind.

   **It is also the only place part of the curation is visible.** The nine
   NCBIfam equivalogs 2026.25.1 admitted to the histidine steps raise the call
   from 160 genomes to 206, and recover 10 of the 39 nutrient-level tests the
   annotation route otherwise loses. On a KO-only genome set that curation cannot
   appear by construction — which is the general point. **Curation aimed at a
   namespace the evaluation cannot see will be scored as worthless by that
   evaluation**, so the screen that proposes such markers and the route that can
   measure them have to be run together.
8. **The reference-consistency figure is measured**, and it is not one number.
   `06-figure-phenotype.R` writes `phenotype-reference-consistency.tsv` and draws
   it as Figure 8d. Urease activity against urea utilisation agrees on 560 of 563
   genome-backed strains, which is the clean case the urea slice found at a
   smaller sweep. Tryptophanase activity against indole production agrees on only
   321 of 351, in both directions — 19 strains produce indole with no
   tryptophanase recorded and 11 the reverse. **The 385-of-386 figure the urea
   slice reported was true of one capability and is not true of the reference as
   a whole**, and a recall must be read against the ceiling of its own assay pair
   rather than against the best one available. Quoting the urea number as though
   it bounded the whole section would have flattered every recall in it.

9. **Both halves of R9 are now on one sweep.** The caution in item 6 was
   written about comparing our figures with someone else's and it applies with
   the same force inside one section: `03-phenotype.R` had been re-run against
   the enlarged sweep and `04-auxotrophy.R` had not, so the catabolic and
   anabolic halves of R9 were measured on different reference sets and the two
   were being reported side by side. `04` is re-run and §5.2 is updated. 171
   strain–medium pairs over 129 genomes become 264 over 201, and 3 644
   biomass-essential tests become 5 803.

   **The headline barely moved, and that is the finding.** Recall goes 0.849 →
   0.844, and no per-nutrient row moves by as much as 0.07 in either direction.
   A 59% larger and taxonomically broader test set leaving the number where it
   was is evidence that the anabolic figure is a property of the catalogue
   rather than of the sweep — which is exactly what the catabolic half could not
   claim, where `glcnac_degradation` moved from n = 119 to n = 229 and the
   recall with it. The rule earns its keep in both directions: applied to the
   catabolic half it caught a real artefact, and applied to the anabolic half it
   confirmed there was none.

Deferred, with rows in [the deferral register](deferral-register.md):

- **Regulatory and defense GIFT validation.** No phenotype reference exists.
  Unblocks if the antimicrobial detoxification proposal is adopted, at which
  point BacDive's `antibiotic resistance` field becomes a reference for
  `beta_lactam_detoxification` and `chloramphenicol_detoxification` — with the
  standing caution that resistance is a phenotype with many causes and a
  detoxification GIFT claims only one of them.
- **The nine most-measured carbon substrates that gifter does not curate.**
  A prioritisation signal, not an evidence problem.
- **An auxotrophy reference set.** No adopted source records an organism
  *failing* to grow without a nutrient, so the one direction that could falsify
  a positive anabolic call is unavailable. §2 has the argument.

## 10. How these numbers were obtained

Probed 2026-08-23 against live services; `data-raw/phenotype_reference_probe.R`
regenerates every figure in sections 1 to 4 and prints the sample seed. The
measured results in §5, §8 and §9 come from `manuscript/analysis/01-marker-matrix.R`,
`03-phenotype.R`, `04-auxotrophy.R`, `05-annotation-route.R` and
`06-figure-phenotype.R`, whose committed outputs are in
`manuscript/analysis/output/`. Nothing
here may enter the manuscript until a committed script in `manuscript/analysis/`
has produced it, per the standing rule of `manuscript/manuscript.md`.

| Figure | Source |
|---|---|
| Catalogue counts, anchors, EC cross-references, KO reachability | `inst/extdata/gifter.sqlite`, database 2026.24.1, schema 7 |
| BacDive coverage, metabolites, enzymes | `https://api.bacdive.dsmz.de/v2/fetch/{id}`, 400 IDs sampled from 1–180 000 at seed 11, 227 valid |
| BacDive strain and assembly totals | BacDive in 2025, *Nucleic Acids Research* 53:D748 |
| MediaDive media and strain links | `https://mediadive.dsmz.de/rest/media`, `/rest/medium-strains/{id}`, 12 defined media sampled at seed 1, 8 resolvable |
| Madin trait counts and vocabularies | `bacteria-archaea-traits`, `output/condensed_traits_NCBI.csv` |
| KEGG genome entries and binomials | `https://rest.kegg.jp/list/genome` |
