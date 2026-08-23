# Assessment: NCBIfam as a marker namespace, read against the deferral register

Status: **assessed 2026-08-22; implemented in database 2026.23.1 and
2026.24.1.** `NCBIFAM` is a registered marker namespace under the three rules of
§5, enforced by the compiler. Release 2026.23.1 is additive: 53 equivalog-grade
profiles joined 25 enzyme components as OR alternatives beside the KEGG
orthologs already there, and no Boolean call moved. Release 2026.24.1 curates
the first capability that depends on the namespace, `siroheme_to_heme_b`, whose
refusal named this assessment as its retrigger. §7 and §8 below record what was
implemented and what was refused inside the implementation.

**Decision timestamp:** 2026-08-22T17:40Z. Implemented 2026-08-23T10:00Z
(additive release) and 2026-08-23T14:30Z (Ahb route).

**Input:** `hmm_PGAP.tsv`, NCBIfam release `hmm_PGAP/20.0`, initiated
2026-06-23 and published 2026-06-25, retrieved 2026-08-22 from
`https://ftp.ncbi.nlm.nih.gov/hmm/current/hmm_PGAP.tsv`. 38,394 profile
records. SHA-256
`972f910ac7c54c6373e286c0d96dee71f643f9abd576a019bcb05ec7f5834b7b`.
The file is not copied into the package. The release name is the pin: it is
recorded in `inst/extdata/database-source/SOURCES.md` and in the `source`
column of every `NCBIFAM` marker row.

**Reproduce:** `Rscript data-raw/ncbifam_equivalog_screen.R`. The target
reaction set below is recomputed by that script rather than read from this
document.

**Companion:** [the deferral register](deferral-register.md), which this
assessment was run against, and
[the marker specificity screen](proposal-marker-specificity-screen.md), whose
KO-to-reaction mapping is reused here.

---

## 1. Why this namespace and not another

gifter already carries five `TIGRFAM` markers. NCBIfam is the collection those
TIGRFAMs are now maintained in: of its 38,394 profiles, 4,483 come from JCVI —
the TIGRFAM library — alongside 8,428 NCBI Protein Cluster profiles and 6,039
NCBIfam-native ones. Admitting `NCBIFAM` is therefore an extension of a
namespace already in the database rather than a new kind of evidence, and
invariant 5 already makes marker identity the extensible pair
`namespace + accession`. The schema places no constraint on the namespace value,
so nothing here is a schema change.

The reason to care is the `family_type` column. NCBIfam grades each profile, and
the **equivalog** grade means the profile's members share one function — the
exact property invariant 16 keeps asking for and the exact property a KEGG
ortholog does not guarantee. 13,888 profiles are equivalog or equivalog_domain.

## 2. What it resolves that KO does not

Two different measurements, and the second is the important one.

**Reaction-level resolution, measured the same way as the KO screen.** 4,623
equivalogs carry a complete EC, and 3,470 of those reach exactly one Rhea
master, covering 1,302 distinct masters. Set against the 3,627 masters that a
single-reaction KO already resolves, 93 are resolved by an equivalog and by no
single-reaction KO. 25 of those 93 are reactions gifter already curates:

| Curated reactions where an equivalog is more specific than any KO |
|---|
| The corrin ring series — cobalt-factor II C20-, cobalt-precorrin-4 C11-, precorrin-2 C20-, precorrin-3B C17- and precorrin-4 C11-methyltransferase, the precorrin-6A and cobalt-precorrin-6A reductases, and both methylmutases |
| 2-oxoglutarate decarboxylase and succinate-semialdehyde dehydrogenase, both on the `oxoglutarate_to_succinate` route |
| Homoserine O-succinyl- and O-acetyltransferase, on the methionine routes |
| Isocitrate lyase, PAPS reductase, ferrochelatase, protoporphyrinogen oxidase, AICAR transformylase, 3-phosphoglycerate dehydrogenase, L-fucose isomerase, citrate lyase, hydroxymethylpyrimidine kinase, oxepin-CoA hydrolase, 2-hydroxymuconate semialdehyde dehydrogenase, the enterobactin synthetase aggregate |

Every one of those reactions sits on a route the specificity screen flagged, or
in `corrin_ring_biosynthesis`, which carries more flagged marker rows than any
other GIFT. The two screens agree about where the evidence layer is thinnest.

**Component-level resolution, which no EC-based count can see.** This is the
larger benefit and the numbers above understate it. Two profiles can share one
EC and still distinguish the proteins that carry it, because the grouping is by
sequence family rather than by reaction. The decisive case is the one the
MetaCyc pass refused:

```text
NF040708.3  equivalog  ahbA  siroheme decarboxylase subunit alpha  EC 4.1.1.111
NF040707.3  equivalog  ahbB  siroheme decarboxylase subunit beta   EC 4.1.1.111
```

KEGG assigns both subunits to `K22225`, and that is why
`siroheme_to_heme_b` was refused: gifter's machinery model requires AhbA AND
AhbB as jointly required components, and one accession matching both cannot
prove a heterodimer. NCBIfam separates them. The refusal's own retrigger
condition is met.

## 3. What it does not resolve

Read against [the deferral register](deferral-register.md), most standing
deferrals survive.

| Deferral | Effect of NCBIfam |
|---|---|
| Ahb route to heme b, `K22225` heterodimer | **Unblocked.** §2 |
| Flagellar coupling ion, MotA/MotB versus PomA/PomB | **Not unblocked.** NCBIfam carries several `motB` equivalogs and a `MotB family protein` subfamily; no profile separates the sodium-driven stator. The refusal stands. |
| Chemoeffector identity | **Improvable, not unblocked.** `NF011622.0` *tar* and `NF011615.0` *tsr* are separate equivalogs, so the existing `aspartate_chemoreception` marker could be tightened beyond a generic chemoreceptor. It does not create a new capability. |
| Type III and type VI secretion | **Partly unblocked, and it changes the argument.** The refusal was that system identity needs co-localisation. NCBIfam carries 28 type VI profiles named for the system itself — `tssH`, `tssM`, `tssD`, `tssO`, `tagQ`, `vasI` and others. A set of system-specific components is not the same evidence as an unordered set of homologous ones, so the co-localisation objection has to be re-argued rather than assumed. See [genomic context](proposal-genomic-context.md). |
| Aminoglycoside modification | **Not unblocked.** The block was that no marker resolves the drug *class*; NCBIfam resolves individual enzymes, which is the same drug-level resolution CARD offered and the same reason it was declined. |
| Macrolide esterase `ereA`, caffeine N-demethylase | **Possibly unblocked.** Both were blocked by "no KO exists", which is a statement about KEGG, not about evidence. Both need a profile check before the deferral is re-read. |
| Ring-hydroxylating dioxygenase substrate identity | **Not unblocked.** The families are polyspecific as proteins, not merely as annotations. Section 2 of the specificity screen: a promiscuous enzyme stays promiscuous however finely the family is drawn. |
| Polyhydroxybutyrate, `K03821` | **Needs a check.** The block is that PHA synthases span substrate classes; whether an equivalog resolves the PHB-specific synthase is an open question. |
| Variant and SNP resistance | **Never.** The evidence layer has no accession for a residue, and a profile is not a residue. |
| CRISPR array context, PUL substrate context | **Not unblocked.** Both need genomic context, which is a different axis. |

## 4. The cost side

Three costs, none prohibitive, all real.

- **Users must be able to produce the accessions.** NCBIfam profiles are what
  PGAP, AMRFinderPlus and bakta run, and InterProScan carries the collection, so
  an NCBIfam accession is obtainable from ordinary MAG annotation. It is not,
  however, what a KEGG-based pipeline emits, so a marker in this namespace is
  evidence some users will silently lack. That argues for admitting NCBIfam as
  an **additional** marker on a component — an OR alternative that raises
  sensitivity — rather than as a replacement for a KO that already works.

  Concretely, and this is the answer to "why do I get no NCBIfam hits":

  | Pipeline | Emits NCBIfam accessions |
  |---|---|
  | NCBI PGAP | Yes. It *is* the library PGAP runs; `NF*` and `TIGR*` accessions appear directly |
  | AMRFinderPlus | Yes, for the subset of the library flagged `for_AMRFinder` |
  | bakta | Yes. It ships the NCBIfam HMM library and reports the hit accession |
  | InterProScan | Yes, as the NCBIfam member database; the same accessions, versioned |
  | KofamScan, BlastKOALA, GhostKOALA | **No.** KEGG orthology only |
  | eggNOG-mapper | **No** NCBIfam accession; its KEGG output is KO |
  | dbCAN / run_dbcan | **No.** CAZy families and eCAMI clusters only |

  A genome annotated only against KEGG therefore matches no `NCBIFAM` marker,
  and that is not a failure: every component the namespace touches in release
  2026.23.1 already accepts a KO, so the call is what it always was. The one
  place it matters is `siroheme_to_heme_b`, which exists *because* KEGG cannot
  express it, and which a KEGG-only annotation will therefore never complete.
- **A second namespace is a second migration surface.** The dbCAN lesson in
  `data-raw/reference/README.md` applies: accessions must be pinned to a release
  and re-checked when it changes. NCBIfam accessions are versioned
  (`NF040708.3`), which is better than eCAMI clusters, but the version suffix
  has to be curated deliberately rather than copied from whatever the annotator
  emitted.
- **`family_type` must be curated, not assumed.** Only the equivalog grades
  carry the one-function guarantee. A `subfamily` or `domain` profile is exactly
  the kind of over-broad evidence invariant 16 refuses, and admitting the
  namespace without also curating the grade would import that breadth silently.

## 5. Recommendation

Admit `NCBIFAM` in a dedicated curation release, under three rules:

1. **Equivalog grades only.** `equivalog` and `equivalog_domain`; every other
   `family_type` is refused as a marker, and the grade is recorded in the
   marker's `notes`.
2. **Versioned accessions**, pinned to a named NCBIfam release recorded in
   `SOURCES.md`, re-checked on upgrade as a marker-layer migration.
3. **Additive first.** The first release adds NCBIfam markers as OR alternatives
   beside existing KO markers on the 25 reactions in §2, changing no call that
   currently fires. Only after that does a release curate a GIFT that depends on
   the namespace.

The first capability to depend on it should be the Ahb route from siroheme to
heme b, because its refusal was recorded with exactly this retrigger, the
biology is settled, and the two subunits are the smallest possible demonstration
that the namespace does something KO cannot.

## 6. Retrigger

- An NCBIfam release that adds equivalogs for chemistry gifter curates.
- Any deferral in the register whose blocking reason is "no KO exists".
- A decision on [genomic context](proposal-genomic-context.md), which would
  reopen the secretion-system argument from the other side.

---

## 7. What release 2026.23.1 implemented, and what it refused

The target reaction set is **recomputed**, not copied from §2:
`data-raw/ncbifam_equivalog_screen.R` reproduces the numbers above from the
pinned release and Rhea 141 — 13,888 equivalog-grade profiles, 4,623 with a
complete EC, 3,470 reaching exactly one Rhea master over 1,302 masters, 93 of
which no single-reaction KO resolves, 25 of which gifter curates. The script
emits the 25 reactions and their candidate profiles to
`data-raw/reference/ncbifam-curated-reaction-gain.tsv`.

53 profiles were admitted on 25 components across 24 reactions. The
twenty-fifth reaction and four individual profiles were refused, and the
refusals are the point of this section: the grade filter is necessary and not
sufficient, and EC agreement is a necessary condition and not a sufficient one.

### 7.1 Refused inside the target set

| Refused | Reaction | Why |
|---|---|---|
| `TIGR01412.1` *efeB* | `RHEA:22584` protoporphyrin ferrochelatase | It shares EC 4.98.1.1 with HemH and runs the chemistry backwards. EfeB and YwbN are exported heme-containing deferrochelatase/peroxidases homologous to the dye-decolorizing peroxidase Dyp; admitting one as evidence of iron *insertion* would let a heme-degrading protein complete heme biosynthesis |
| `NF005262.1` E22 family | `RHEA:13701` homoserine O-acetyltransferase | NCBIfam's own note says members "resemble the MetX family … but appear distinct from those enzyme families", and the solved structure 5JKF is deposited as esterase E22. The EC is inherited from resemblance |
| `TIGR01392.2` *metX* | `RHEA:13701` homoserine O-acetyltransferase | The model withdraws the guarantee its grade otherwise carries: "assignments made by this HMM are somewhat uncertain", because one residue change converts the acetyl activity into the succinyl one. Since the acetyl and succinyl transfers are two separate curated reactions, a model that cannot separate them is the one thing this namespace was admitted to avoid. 3 RefSeq hits |
| `NF046063.1` oxepin-CoA hydrolase | `RHEA:31755` | Two independent reasons. It is named an "alternative type", so attaching it to the PaaZ hydrolase-domain component would assert a homology the profile denies, and admitting it as its own enzyme system is a route claim rather than a marker addition. Separately, its function assignment is computational — inferred from TnSeq fitness data, not characterised — so it is `putative` evidence at best. `RHEA:31755` therefore gains nothing in this release |

`RHEA:31755` is the twenty-fifth reaction, and it is deferred rather than
closed: an oxepin-CoA hydrolase enzyme system for the alternative-type protein
is curatable once its chemistry is read.

### 7.2 Two profiles admitted after a second look

Both would have been easy to refuse on their metadata alone, and both are
correct:

- `TIGR00562.1` carries `gene_symbol = hemG`, which reads like the wrong enzyme:
  gifter's `RHEA:25576` is the *oxygen-dependent* protoporphyrinogen oxidase, and
  *Escherichia coli* HemG is a small flavodoxin running the quinone-dependent
  reaction `RHEA:27409`, which gifter curates separately. The model is not HemG.
  Its label is `proto_IX_ox`, it is 470 positions long against the 468 of the
  HemY profile `NF008845.0`, and its description is a flavoprotein with a
  dinucleotide-binding motif oxidising protoporphyrinogen IX with oxygen. The
  gene symbol is a naming artefact.
- `TIGR00109.1` *hemH* covers protoporphyrin and coproporphyrin ferrochelatase
  together. That is real breadth, but it is the *same* breadth `K01772` already
  carries on the same component, so the marker does not widen the claim; it
  widens which annotations can satisfy it.

### 7.3 Where the namespace separates what KEGG joins

Four of the 24 reactions gain more than annotation coverage. The corrin-ring
series is the largest: `K03394`, `K05895`, `K05936` and `K06042` each name a
pair of cobalt and non-cobalt reactions that gifter curates as two reactions, so
the KO sits on both components while the equivalog states one. The methionine
pair is the same shape from the other side — `K00641` and `K00651` are each
annotated for the acetyl and succinyl transfers together, while `NF001209.0`
states the acetyl one and `NF003776.0`, `NF006449.0` and `TIGR01001.2` state the
succinyl one. `RHEA:13213` gains the NADP cofactor its curated name states and
its KOs do not. `RHEA:34219` gains the hydroxymuconate activity that `K10217`
reports jointly with the aminomuconate one.

None of this narrows an existing call. The KOs stay where they are: this
release adds evidence, and removing an over-broad KO from a component is a
different decision with a different call effect.

### 7.4 How the additive claim is proved

Not asserted — computed, in `test-ncbifam-namespace.R`. The release preceding
this one is reconstructed by deleting every `NCBIFAM` row from the source tables
and recompiling with the same compiler, and both databases are evaluated over
the same marker sets: the entire pre-NCBIfam marker vocabulary, 24 deterministic
one-third subsets of it, and the vocabulary of each of the 25 components the
release touched. Every GIFT's `complete`, `evidence_confidence`,
`number_of_complete_implementations`, `best_implementation` and both
missing-requirement counts are identical in every case.

The structural half of the claim is checked separately and is the reason the
behavioural half holds: every `NCBIFAM` evidence row sits on a component that
already accepted a marker. No component became newly satisfiable, and no
component, system, reaction or route entered the hierarchy.

---

## 8. Release 2026.24.1: the Ahb route, verified end to end

The first capability that depends on the namespace, and the reason §5 said it
should be this one: the refusal recorded in
[the MetaCyc pass](proposal-metacyc-expansion.md) named exactly this retrigger.

**A heterodimer is not a route.** The refusal was about one reaction, so it
would have been possible to satisfy it and still ship a fragment. Every step was
therefore checked at the specificity the claim needs before anything was
curated:

| Step | Rhea master | Evidence | Verdict |
|---|---|---|---|
| Siroheme to 12,18-didecarboxysiroheme, AhbA **and** AhbB | `RHEA:19093` | `NF040708.3` *ahbA* and `NF040707.3` *ahbB*, both equivalog, EC 4.1.1.111 | Two jointly required components, each with its own accession. `K22225` is admitted on neither |
| 12,18-didecarboxysiroheme to Fe-coproporphyrin III, AhbC | `RHEA:37431` | `K22226` names one gene and one activity; `TIGR04546.1` is an equivalog for the same protein | Specific. The KO carries no EC, so the specificity screen cannot see it, but a one-gene one-activity orthology states one reaction |
| Fe-coproporphyrin III to heme b, AhbD | `RHEA:56520` | `K22227`, EC 1.3.98.6; `TIGR04545.1` equivalog | Specific. EC 1.3.98.6 is the AdoMet-dependent conversion and does not cover the peroxide-dependent one |
| Alternative terminal step, HemQ | `RHEA:56516` | `K00435`, already curated on `heme_b_biosynthesis` | Already in the database. KEGG M00847 admits it as an alternative for the same step |

Both minimal routes are materialised: `AHB_AHBD` and `AHB_CHDC` differ only in
the terminal reaction. That is what lets the `M00847` link be recorded
`equivalent` rather than `subset_of` — the module's own definition is
`K22225 K22226 (K22227,K25033)`, and gifter represents the same alternative.

### 8.1 What the namespace bought, stated exactly

`K22225` is admitted nowhere in the database, and a test asserts it. A genome
that KEGG calls complete for M00847 on a single `K22225` gene is **not** complete
in gifter, because that gene cannot be both subunits of a heterodimer. The
NCBIfam profiles are the only evidence that separates them, so this GIFT is the
one place where a KEGG-only annotation can never produce a positive call. That
is a real cost, and it is the honest one: the alternative was to keep refusing
the capability.

### 8.2 Refused inside the Ahb curation

- **`NF046668.3`, the fused NirDL-like siroheme decarboxylase.** Some organisms
  carry AhbA and AhbB as one polypeptide, and a fusion-specific marker was
  listed in the original refusal as one of the three things that would unblock
  it. NCBIfam has a profile — and it is `domain`-graded, so it carries no
  one-function guarantee and is refused by rule 1. The fused enzyme therefore
  remains uncallable, which under-calls real biology rather than over-calling
  it.
- **`K25033`.** KEGG splits the peroxide-dependent heme synthase across two
  orthology groups, `K00435` and `K25033`, with identical names and EC numbers.
  gifter curates `K00435` only, from the earlier coproporphyrin curation. Adding
  `K25033` would change `heme_b_biosynthesis` calls, which is a decision of its
  own rather than a side effect of this release; it is recorded in the register.

### 8.3 Composition

`SIROHEME` and `HEME_B` are both existing anchors, and 12,18-didecarboxysiroheme
and Fe-coproporphyrin III stay internal — neither is a boundary, a branchpoint
or a stable product anything else touches. The GIFT therefore adds no anchor,
and it composes with `siroheme_biosynthesis` through the declared `SIROHEME`
anchor alone. The graph edge from `siroheme_biosynthesis` that
`test-siroheme.R` used to assert *absent* is now asserted present, with the
comment recording why it appeared: the boundary did not move, the evidence did.
