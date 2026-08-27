# Three curation leads found by the phenotype benchmark

Status: **assessment, with two of the three leads now carried through.** Each
lead names a capability the phenotype layer says gifter under-calls, the reaction
responsible, and what would fix it. Two of the three were unblocked and needed
only curation; the third needed a decision first.

- §1 `glcnac_degradation` — **decided and curated, database 2026.26.1.** The
  decision is §1.1; the marker gain is §1.2.
- §2 `serine_biosynthesis` — still open. The direction question is unanswered
  and has a row in the deferral register.
- §3 `histidine_biosynthesis` — **curated, database 2026.25.1.**

These are the first findings the validation layer of
[the phenotype assessment](proposal-phenotype-validation.md) has produced, and
they are the reason it was built. Each was found the same way: an organism
observed to do something, a genome called unsupported, and gifter's own trace
naming the step that failed.

---

## How they were found

`manuscript/analysis/03-phenotype.R` and `04-auxotrophy.R` report recall against
observed-positive phenotype. Three targets stood out, and all three survive the
filters that disqualify most low scores — the premise holds, no alternative
curated route needed OR-ing, and no component is unreachable on the reference
genome set.

| Target | Observation | n | Recall | Reaction that failed |
|---|---|---|---|---|
| `glcnac_degradation` | GlcNAc as a carbon source | 119 | **0.154** | `RHEA:17417` in 30 of 30 sampled failures |
| `serine_biosynthesis` | Growth without serine | 152 | **0.296** | `RHEA:14329` in 22 of 30 |
| `histidine_biosynthesis` | Growth without histidine | 152 | **0.520** | `RHEA:14465` in 22 of 30, `RHEA:22828` in 15 of 30 |

Prevalence across the 11 908-genome reference set corroborates each: 13.1%,
56.7% and 57.9% respectively. Serine is biomass-essential in every bacterium, so
a capability curated for it that fires in 57% of genomes is under-calling
something, whatever the phenotype layer said.

## 1. `glcnac_degradation`: the route demands an enzyme most users do not have

The single curated route is `GLCNAC_KINASE` — GlcNAc to GlcNAc-6-phosphate by a
cytoplasmic kinase, then deacetylation, then deamination to fructose-6-phosphate.
Marker prevalence over the reference set explains the call rate exactly:

| Step | Reaction | Marker | Genomes |
|---|---|---|---|
| Kinase | `RHEA:17417` | `K00884` | **950 (8.0%)** |
| Deacetylase | `RHEA:22936` | `K01443` | 7 108 (59.5%) |
| Deaminase | `RHEA:12172` | `K02564` | 5 656 (47.3%) |

The downstream chemistry is in half the catalogue and the kinase is in a
twelfth. That is not an annotation gap: **most bacteria import
N-acetylglucosamine through a PTS transporter, which phosphorylates it during
transport**, so they arrive at GlcNAc-6-phosphate having never needed a
cytoplasmic kinase. gifter's route asks for an enzyme those organisms genuinely
do not encode, and then reports them as unable to use GlcNAc.

**This needs an architectural decision, not a marker.** Three options, and they
are not equivalent:

- Curate a second route entering at GlcNAc-6-phosphate, which requires deciding
  whether PTS-mediated uptake is a curated `transport` GIFT — there are already
  three — or whether the entry point is simply a second declared anchor.
- Move the input boundary to `GLCNAC_6P`, which narrows the claim to intracellular
  processing and makes the kinase a separate upstream capability.
- Leave it, and accept that the trait means "degrades GlcNAc *via the kinase
  route*", in which case the name overstates it and the phenotype crosswalk row
  should be downgraded from `equivalent` to `subset_of`.

The third is the honest fallback and costs nothing. The first is the biologically
right answer and is the larger job.

Separately, and independent of the route question: `NF046059.1` *nagB-II* is an
equivalog-grade profile for a **second deaminase family** that `K02564` does not
cover, along with four more equivalogs on the same reaction. That is a
straightforward marker gain.

### 1.1 The decision, taken 2026-08-27 — database 2026.26.1

**The first option, in the form that adds no anchor and no GIFT: `RHEA:49240`
becomes the first reaction of a second route, `GLCNAC_PTS`, between the same
declared boundaries.** The paragraph above framed this as a boundary question.
It is not one. The boundaries were right the whole time and the *route inventory*
was incomplete.

Two non-homologous mechanisms reach GlcNAc-6-phosphate:

```text
                        GLCNAC  (anchor, unspecified)
                          |
        GLCNAC_KINASE     |     GLCNAC_PTS
    RHEA:17417, ATP       |     RHEA:49240, PEP-dependent
    cytoplasmic NagK      |     group translocation by NagE
                          v
              N-acetylglucosamine 6-phosphate  (internal)
                          |
                  RHEA:22936 deacetylase
                          |
                  RHEA:12172 deaminase
                          v
              FRUCTOSE_6P + AMMONIUM  (anchors)
```

That is invariant 6 in its ordinary form — a non-homologous replacement for one
step — resolved at the **route** layer rather than the enzyme-system layer,
because the two entries are genuinely different reactions with different
substrates, not two enzymes for one reaction.

**Why not a `transport` GIFT.** The three uptake precedents translocate a
molecule unchanged and declare `X_EX` in, `X_IN` out. The PTS does chemistry: it
phosphorylates in transit, so a `glcnac_uptake_pts` GIFT would have to declare
`GLCNAC_6P` as its output anchor, and `glcnac_degradation` would then have to
declare that internal intermediate as a second input to compose with it. The
polysaccharide proposal already decided this class of case, in §4.5: *"The
transporter is a required route reaction, not an adjacent GIFT. This is the
architecture working as intended: the anchors determine the route content."*

**Why not the `GLCNAC_6P` boundary.** Invariant 3 keeps the anchor vocabulary
small and invariant 17 forbids minting a boundary molecule to make something
fit. GlcNAc-6-phosphate is an internal intermediate of both routes. Declaring it
would also break the composition edge from `chitin_degradation`, whose output
anchor is `GLCNAC`, and would leave a one-reaction kinase GIFT — the "arbitrary
single-step fragment" invariant 9 refuses.

**Why not the fallback.** Worth stating precisely, because the fallback as
described does not do what it says. `subset_of` is *recall-usable* — the reader
in `manuscript/analysis/_common.R` admits `equivalent` and `subset_of` alike,
because an observation narrower than the target still implies it. Downgrading the
BacDive and Madin rows to `subset_of` would have changed the recall table by
nothing at all. Silencing the benchmark would have needed `superset_of`, which
discards all 119 observations — throwing away the only external evidence that
found the problem, in order to stop it reporting the problem. The crosswalk rows
therefore stay `equivalent`, and they now describe a capability that means what
its name says.

**The compartment question, answered rather than dodged.** `GLCNAC` stays
`unspecified`, and that is a positive decision. The two entries start on opposite
sides of the membrane: the PTS substrate is necessarily extracellular, while the
kinase also serves GlcNAc recovered from the organism's own peptidoglycan inside
the cell — which is exactly what `K28208` was already curated for, as "cell wall
recycling kinase acting on the same chemistry". Specifying either compartment
would make the anchor false for one of its own routes. Rule 1b of the
polysaccharide decisions says unlicensed chemistries stay compartment-
unspecified, and rule 1d keeps the `chitin_degradation` edge traversable and
flagged. Whether to split the anchor and license amino sugar cross-feeding is a
separate question and is now its own row in the deferral register.

**What EI and HPr are, and why they are not components.** The Rhea master writes
the substrate as N(pros)-phospho-L-histidyl-[protein] — that is HPr, regenerated
from phosphoenolpyruvate by enzyme I in a different reaction. It is a
phosphoryl-carrier cofactor in exactly the sense ATP is a phosphoryl carrier for
`RHEA:17417`, and gifter curates no cofactor regeneration anywhere. Requiring
them would have cost 48 genomes and started a policy the register already lists
as unsettled for oxygenase reductases. `SYS_49240_NAGE` therefore curates the
substrate-specific enzyme II alone.

**What was refused.** The mannose PTS ManXYZ moves glucose, mannose, fructose,
glucosamine and N-acetylglucosamine through one enzyme II. Admitting it would
equate `glcnac_degradation` with four sugars it does not claim, which is the
damage invariant 16 describes. `K02793`–`K02796` and `K25814` are admitted
nowhere, the refusal is in the deferral register, and `test-sugar-degradation.R`
asserts that they match no marker in the database.

**Effect, measured.** Over the 11 908-genome reference set the enzyme II reaches
2 929 genomes, of which 2 180 carry no kinase at all. With the deacetylase and
deaminase conjunction at 5 090 genomes, the kinase route completes in 1 532, the
PTS route in 2 362, and their union in 3 157 — from 12.9% of the catalogue to
26.5%. That is a doubling and it is not a fix. **The remaining ceiling is the
downstream conjunction at 42.7%**, which no boundary choice could have moved and
which the marker gain below is aimed at.

### 1.2 The marker gain, carried through

Independent of the route decision, and taken in the same release. Ten NCBIfam
equivalogs join the three amino sugar reactions, every declared EC verified
against the reaction cross-reference first, as database 2026.25.1 did for the
histidine markers:

| Reaction | EC in `reaction_xrefs` | Profiles admitted |
|---|---|---|
| `RHEA:17417` | 2.7.1.59 | `NF009835.0`, `NF046058.1` |
| `RHEA:22936` | 3.5.1.25 | `TIGR00221.1`, `NF008371.0` |
| `RHEA:12172` | 3.5.99.6 | `TIGR00502.1`, `NF046059.1`, `NF001685.0`, `NF001682.0`, `NF009022.0`, `NF041128.1` |
| `RHEA:49240` | 2.7.1.193 | `TIGR01998.1`, `NF007608.0` |

`NF046059.1` *nagB-II* is the one the lead named: a structurally distinct
deaminase family `K02564` does not cover, so a genome carrying only NagB-II was
failing a reaction it can perform. The deacetylase pair was added beyond the
lead's scope for one reason — without it, the middle step of both amino sugar
routes had no NCBIfam evidence, and a genome annotated only against NCBIfam
could complete neither route. It can now complete both, which is the property
`test-sugar-degradation.R` checks.

The gain does not show in the prevalence table, and that is expected rather than
disappointing: the reference set is KEGG's own per-genome KO assignment and
reaches no NCBIfam profile at all. The benefit falls to users who annotate
against NCBIfam, and the honest way to state it is that it is unmeasured here
rather than zero.

## 2. `serine_biosynthesis`: the direction question, decided

**Decided 2026-08-27, in database 2026.27.1.** No second route into `SERINE` is
curated. The glycine entry is refused in all three shapes it could take, the
non-phosphorylated route is deferred with its block restated precisely, and the
register row moves from section 3 to section 1 — because the investigation
that this section opened concluded the opposite of what it assumed. §2.6 is the
decision record; §2.1 to §2.5 are the evidence.

### 2.1 What the lead said, and what it got wrong

The curated route is `SER_PHOSPHORYLATED`, the three-step phosphorylated
pathway. Its markers are well covered — 3-phosphoglycerate dehydrogenase
`K00058` at 84.4%, phosphoserine aminotransferase `K00831` at 73.9%,
phosphoserine phosphatase `K01079` at 60.5% — and their conjunction lands near
the observed 56.7%. The NCBIfam screen offers **nothing** on either weak step:
`RHEA:14329` and `RHEA:21208` appear in `ncbifam-curated-reaction-gain.tsv` with
no candidate profiles at all, while `RHEA:12641` collects two and the histidine
phosphatase five. This section concluded from that: *when a screen that
productive finds nothing, the shortfall is not marker resolution — what is
missing is a route.*

That inference does not survive decomposing the shortfall. Over the
11 908-genome reference set, using the KO layer that set can reach:

| Marker set | Genomes | Share of the frame |
|---|---:|---:|
| Complete `SER_PHOSPHORYLATED` | 6 716 | 56.4% |
| serA + serC, no recognised phosphatase | 1 622 | 13.6% |
| No marker of any of the three steps | 1 288 | 10.8% |
| Other partial sets | 2 282 | 19.2% |

Of the 5 192 incomplete genomes, 2 725 are missing exactly one step and 1 622 of
those are the phosphatase alone — the annotation gap the amino acid proposal
recorded when it decided to keep the step required. The 1 288 carrying no marker
of the pathway at all are the only class a second route could rescue on route
grounds, and their leading genera are *Chlamydia* (118), *Rickettsia* (55),
*Wolbachia* (43), *Mycoplasma* (41), *Borrelia* and *Borreliella* (51),
*Spiroplasma* (25) — obligate intracellular and host-restricted organisms whose
serine auxotrophy is not a gifter under-call but the reason they are obligate.
Part of the 43.6% is real.

### 2.2 The benchmark failures are all missing a step of the curated route

The decisive measurement is over the phenotype layer's own disagreements —
`manuscript/analysis/output/auxotrophy-disagreements.tsv`, joined back to the KO
matrix that produced the calls, so that each row says which step the genome
lacks rather than only that the GIFT was unsupported. Of the 86 distinct
organisms observed to grow on a defined medium supplying no serine and called
unsupported by gifter:

| Missing reactions | Organisms |
|---|---:|
| `RHEA:14329` alone | 43 |
| `RHEA:14329` + `RHEA:21208` | 15 |
| `RHEA:21208` alone | 13 |
| `RHEA:12641` alone | 8 |
| two steps, other combinations | 7 |
| **all three steps** | **0** |

**Not one failure is missing the whole pathway.** Every organism the benchmark
disagrees with carries at least one step of `SER_PHOSPHORYLATED` and is missing
one or two of the others, 62 of the 86 the aminotransferase. A second route is
not what those genomes need; markers on the steps they already half-satisfy is.
The lead's premise — that a productive screen finding nothing proves the
shortfall is not marker resolution — confuses *the NCBIfam screen finding
nothing* with *no marker existing*. The former is a fact about one namespace at
one grade.

### 2.3 The glycine entry: what it would actually do

`RHEA:15481` is curated `reverse` inside `glycine_biosynthesis`, whose Rhea
master runs glycine to serine. Its forward direction is the same enzyme and is
real biology. It is also carried by `K00600`, which is in 11 493 of the 11 908
reference genomes — **96.5%**.

Adding it as an entry into `SERINE` would move the GIFT from 6 716 genomes to
11 569, a gain of **4 853**. Three facts about that gain:

- **3 471 of the 4 853 carry no complete glycine cleavage system.** In gifter's
  database the only anabolic producer of `GLYCINE` is `glycine_biosynthesis`,
  whose input is `SERINE`. For those genomes the claim would read: this genome
  makes serine from glycine, which it makes from serine.
- **1 092 of the 1 288 genomes with no phosphorylated-route marker at all carry
  `K00600`** — including 118 of 118 *Chlamydia*, 55 *Rickettsia*, 43
  *Wolbachia*. The route would call the reference set's clearest serine
  auxotrophs serine prototrophs.
- **It would rescue at most 9 of the 86 benchmark failures on biology.** Only 9
  carry a complete glycine cleavage system and only 3 carry it with
  formate–tetrahydrofolate ligase. The other 75 would flip to positive on
  `K00600` alone, which is not the benchmark being satisfied but the trait
  ceasing to discriminate: recall would rise to ~0.98 because the call would be
  ~0.97 everywhere.

The biology behind all three numbers is one fact. Serine from glycine is not net
serine biosynthesis unless the glycine comes from somewhere that is not serine,
and the second substrate is a one-carbon unit. `RHEA:15481` forward consumes
5,10-methylenetetrahydrofolate; in the serine-to-glycine direction the same
molecule is a *product* and stays internal, which is why
`glycine_biosynthesis` can state its claim with two anchors and this direction
cannot.

### 2.4 What the validator says, in both shapes

Run before curating, against the current sources.

Shape A — `RHEA:15481` forward as a second route of `serine_biosynthesis`, with
`GLYCINE` added as a second input anchor:

```text
gifter source validation failed:
- Circular anabolic GIFT composition:
    glycine_biosynthesis -> serine_biosynthesis -> glycine_biosynthesis
```

Shape B — a separate directed `GLYCINE > SERINE` GIFT:

```text
gifter source validation failed:
- Circular anabolic GIFT composition:
    glycine_biosynthesis -> serine_biosynthesis_glycine -> glycine_biosynthesis
```

**This is invariant 8, not invariant 6, and the `interconversion` exemption does
not reach it.** Invariant 6 asks that alternative routes be represented
explicitly, and an alternative route is an alternative *between the GIFT's
declared boundaries*: `GLCNAC_PTS` is one, because it reaches the same anchors
as `GLCNAC_KINASE` by different chemistry. A glycine entry does not start at
`PG3`. It would change the GIFT's boundary set, and because `gift_anchors`
declares inputs per GIFT rather than per route, `serine_biosynthesis` would then
claim to require glycine on the phosphorylated route and 3-phosphoglycerate on
the glycine route — the over-claim that split methionine biosynthesis in two
(`proposal-amino-acid-biosynthesis.md` §2.2).

The exemption in invariant 8 was written for a cycle that is a *syntactic
consequence of the mode's own contract*: an `interconversion` GIFT must declare
every anchor in both roles, so two adjacent ones cycle by arithmetic and the
loop says nothing about the boundaries
(`proposal-central-metabolic-cycles.md` §9.2). Nothing of that applies here.
Both GIFTs are `anabolic` and each asserts one direction, so the loop is a
claim rather than an artefact — and §2.3 measures the claim it makes.

Following `gifter-context.md` — when a cycle appears, ask which boundary is the
weakest claim rather than deleting an edge — the weakest claim is neither
`SERINE` nor `GLYCINE`. It is the boundary that is missing: the one-carbon pool.
That is the same obstacle already recorded against the glycine cleavage system,
which `proposal-amino-acid-metabolism.md` §12.6 defers because "its product is
methylene-tetrahydrofolate, and the one-carbon pool has no anchors yet", and
against reductive glycine carbon fixation, which the register refuses on
direction. The glycine entry into serine is a one-carbon capability, and gifter
has no one-carbon layer.

### 2.5 The mode change was available, and is the wrong trade

Shape C — making `glycine_biosynthesis` an `interconversion` GIFT with `SERINE`
and `GLYCINE` declared in both roles — **validates cleanly**. It was run. The
edges it creates all cross a mode boundary, so no directed partition acquires a
cycle, and the argument for it is a good one: `K00600` is a single enzyme whose
net direction is set by the cell's one-carbon demand rather than by the protein,
which is a stronger reading of invariant 16 than the one that made
`succinate_fumarate_interconversion` reversible, where `K00239` names two
enzymes an orthology group failed to separate.

It is refused on what it costs and what it delivers:

- It **delivers no route into `SERINE`**. `serine_biosynthesis` would be
  unchanged, at 6 716 genomes and recall 0.296. The graph would gain a
  reversible edge; the call would not move.
- It **breaks a directed claim that measures well**. `glycine_biosynthesis`
  scores recall 0.974 over 151 strains observed to grow without glycine.
  Trading a directed trait that the phenotype layer confirms for a symmetric one
  that changes no call is a worse database.
- Its graph consequence is the one §2.3 objects to, in a form the validator no
  longer reports: a two-node reversible loop between `SERINE` and `GLYCINE`
  standing in for chemistry that requires a one-carbon unit nobody declared.

Recorded here so the option is not re-derived: it works, it is legal, and it
was declined.

### 2.6 Decision

1. **No `GLYCINE` input anchor on `serine_biosynthesis`, and `RHEA:15481` is
   not curated forward.** It stays in exactly one route, `GLY_SHMT`, oriented
   `reverse`. `glycine_biosynthesis` stays `anabolic`. Recorded as
   `DBC-20260827-SERINE-GLYCINE-DIRECTION` and guarded by a test, on the model
   of `DBC-20260817-HOMOCYSTEINE-INPUT-ONLY`.
2. **The retrigger is the one-carbon anchor layer**, not a direction decision.
   When methylenetetrahydrofolate and formate become boundaries, the glycine
   entry becomes statable — as part of a capability that also says where the
   glycine came from — and this row should be re-read together with the glycine
   cleavage system and reductive glycine fixation.
3. **The non-phosphorylated route is deferred, and it is not the cleaner first
   step.** §2.7.
4. **The shortfall is marker coverage on `RHEA:14329` and `RHEA:21208`**, and
   the register row moves to section 1. One admission follows immediately:
   `K28205`, in §2.8.

### 2.7 The non-phosphorylated route has a direction problem too, and no entry

The route is glycerate to hydroxypyruvate to serine.
`proposal-amino-acid-biosynthesis.md` §7 excluded it for "weak and ambiguous KO
support". That is now measurable, and it is worse than weak:

| Step | Reaction | Best marker | Verdict |
|---|---|---|---|
| 3-phosphoglycerate to D-glycerate | EC 3.1.3.38 | **none** | Neither screen gifter keeps reaches it. `ko-reaction-specificity.tsv` holds no KO for the EC, and the only `PG3`-adjacent NCBIfam equivalogs are mannosyl-3-phosphoglycerate phosphatases, a different substrate |
| D-glycerate to hydroxypyruvate | `RHEA:17905` | `K00018` *hprA*, `single_reaction` | Clean. 1 898 genomes, 15.9% |
| hydroxypyruvate to L-serine | `RHEA:22852`, reverse | `K13290`, `single_reaction` | Clean but 33 genomes, 0.3% |

`K00018` and `K13290` **co-occur in zero of the 11 908 reference genomes.** The
route as gifter could defensibly evidence it is complete nowhere. Widening the
transaminase to `K00830` *AGXT* — three ECs, four Rhea masters, named for
alanine-glyoxylate and serine-glyoxylate transamination — brings the pair to
496 genomes and rescues 4 benchmark failures, and is exactly the over-broad
marker invariant 16 refuses: accepting it would equate a serine biosynthesis
claim with glyoxylate detoxification. The same objection retires `K00049`
*GRHPR* on the reductase step, which is dual-specificity and named for the
opposite direction.

Two things follow. It **cannot be a route of `serine_biosynthesis`** at all,
because with no marker for the entry step it cannot share that GIFT's `PG3`
input boundary; it would need a `GLYCERATE` anchor with no curated producer, and
so a separate GIFT. And its markers carry the same direction ambiguity the
glycine entry does — `hprA` and the serine-pyruvate transaminase are
characterised running serine *to* glycerate, which is the serine cycle and
serine catabolism. The claim that it is the cleaner first step because it has no
direction problem does not hold.

Deferred to section 1 of the register, blocked on markers rather than on an
axis, with the retrigger stated: an accession for EC 3.1.3.38, and a
transaminase family for `RHEA:22852` that reaches more than 33 genomes.

### 2.8 One marker the investigation did find

`K28205` *E2.6.1.52* is a second orthology group for `RHEA:14329` that gifter
does not curate. It is admitted in database 2026.27.1 with
`confidence = ambiguous`; the reasoning and the standing doubt are in
`DBC-20260827-PHOSPHOSERINE-TRANSAMINASE-ARCHAEAL`. It reaches 50 genomes,
completes the route in 48, and rescues 1 of the 86 benchmark failures. It is a
small gain, and it is the whole of what the reaction offers in the KO namespace:
`RHEA:14329` is reached by `K00831` and `K28205` and nothing else.

Three further orthology groups reach `RHEA:21208` and all three are refused in
the same pass. `K05518` *rsbX* and `K07315` *rsbU_P* carry EC 3.1.3.3 because
they dephosphorylate a phosphoserine *residue* on an anti-anti-sigma factor, not
the free metabolite: they are the sigma-B stress regulon, and accepting them
would add 90 genomes, rescue none of the 86 failures, and equate a
stress-response protein phosphatase with metabolic phosphoserine phosphatase —
the damage invariant 16 describes, done to the regulatory side as much as to
this one. `K15781` *serB-plsC* goes with them: KEGG's own name calls the
phosphatase activity putative and the protein also carries an acyltransferase.
All three are recorded in the register as refused rather than deferred.

That leaves the honest measure of this lead. `serine_biosynthesis` under-calls
because the phosphoserine phosphatase step is solved by promiscuous HAD-family
enzymes that orthology does not group and NCBIfam does not grade, and because a
tenth of the reference set genuinely cannot make serine. Neither is fixed by a
route.

## 3. `histidine_biosynthesis`: unblocked, and the profiles are already listed

Two steps carry the shortfall, and both are textbook non-homologous replacement:

| Reaction | Enzyme | Curated markers | Best marker prevalence |
|---|---|---|---|
| `RHEA:14465` | Histidinol-phosphate phosphatase | `K04486`, `K05602`, `K18649`, `K28842`, `K01089` | 22.8% |
| `RHEA:22828` | Phosphoribosyl-ATP pyrophosphohydrolase | `K11755`, `K14152`, `K01523` | 38.7% |

The phosphatase is known to be solved by at least three unrelated protein
families, and the orthology namespace splits it accordingly. gifter already
carries five KOs for it and still misses.

**`NCBIFAM` was admitted in database 2026.23.1, and the screen already lists the
profiles that close this.** From `ncbifam-curated-reaction-gain.tsv`:

| Reaction | Profile | Grade | Gene | Sequences |
|---|---|---|---|---|
| `RHEA:14465` | `TIGR02067.1` | equivalog | *hisN* | 23 807 |
| `RHEA:14465` | `TIGR01261.1` | equivalog_domain | *hisB* | 19 756 |
| `RHEA:14465` | `NF052360.1` | equivalog | — | 8 656 |
| `RHEA:14465` | `NF005996.1` | equivalog | *hisJ* | 6 700 |
| `RHEA:14465` | `NF052359.1` | equivalog | — | 337 |
| `RHEA:22828` | `NF001610.0`, `NF001611.0`, `NF001613.0` | equivalog | — | — |
| `RHEA:22828` | `TIGR03188.1` | equivalog_domain | *hisE* | — |

Every one is `equivalog` or `equivalog_domain`, the two grades the compiler
admits, so nothing about the namespace policy blocks them.

**The lineage evidence lines up.** *hisN* is the actinobacterial solution to the
phosphatase step, and Actinomycetota dominate the failure list on both halves of
the benchmark — *Streptomyces* contributes 53 of the 651 catabolic failures, the
largest single genus, with *Corynebacterium* next at 25. A benchmark that found
an under-call, a screen that had already listed the fix, and a taxonomy that
explains both is as clear as a curation lead gets.

This one is ready. It needs the marker rows, a release, and the usual
verification that each profile's chemistry is the curated reaction — not an
architectural decision.

## Recommendation

1. **Curate the histidine markers.** Five profiles on `RHEA:14465`, four on
   `RHEA:22828`, verified individually against the reaction. It is a `broadens`
   change and needs its own release entry.
2. **Curate the GlcNAc deaminase families**, `NF046059.1` and its four
   companions, independently of the route question.
3. **Decide the GlcNAc entry boundary** before touching the route. If the answer
   is "not now", downgrade the crosswalk row to `subset_of` so the benchmark
   stops reporting a boundary choice as a failure.
4. ~~**Decide the serine direction question** before curating a second route.~~
   **Decided in database 2026.27.1, against a second route in any shape.** §2.6.
   The direction question turned out not to be the load-bearing one: the
   benchmark's serine failures are missing steps of the route gifter already
   curates, not a route it does not. The register row moves from section 3,
   where it was blocked on an architectural axis, to section 1, where it is
   blocked on markers that do not exist — with the exception of `K28205`, which
   does, and which is curated in the same release.

Nothing here should be done as a data-entry pass. Each item changes what a
positive call means for a capability that is biomass-essential or that a reader
will assume is complete.
