# Assessment: what the NCBIfam namespace unblocks beyond the Ahb route

Status: **assessed 2026-08-25.** No GIFT, marker, route, anchor, schema table or
runtime behaviour changed. **No database release.** The assessment settles three
standing register rows, records one new refusal and seven new deferrals, and adds
one product to `data-raw/ncbifam_equivalog_screen.R`: a discovery table for the
9,650 equivalog profiles the EC join cannot see. One candidate is reported ready
to curate and deliberately left uncurated — every new GIFT is a `broadens` call
change and needs its own release decision.

**Decision timestamp:** 2026-08-25T04:50Z

**Inputs, unchanged from the release that admitted the namespace:** NCBIfam
release `hmm_PGAP/20.0`, 38,394 profile records, SHA-256
`972f910ac7c54c6373e286c0d96dee71f643f9abd576a019bcb05ec7f5834b7b`; Rhea
release 141; KEGG orthology as of 2026/08/22. Every input was read from
`data-raw/reference/.cache` with `--offline`, and the digests match those
recorded in [the NCBIfam assessment](proposal-ncbifam-namespace.md) §7. Nothing
was re-fetched: a newer NCBIfam release is a marker-layer migration and a
different task.

**Tool:** `Rscript data-raw/ncbifam_equivalog_screen.R --offline`

**Companions:** [the NCBIfam assessment](proposal-ncbifam-namespace.md), whose
§7 refusals are the standing evidence that the grade filter is necessary and not
sufficient; [the marker specificity screen](proposal-marker-specificity-screen.md),
whose discovery product this pass finally gives the NCBIfam screen an equivalent
of; and [the deferral register](deferral-register.md), which this assessment was
run against and which changes in the same commit.

---

## 1. The question, and what this pass may not do

`NCBIFAM` was admitted in database 2026.23.1 and first depended on in 2026.24.1,
where it separated AhbA from AhbB and let a four-year-old refusal close. The
question here is what *else* it unblocks, asked in three streams of decreasing
expected yield and increasing cost.

The pass is bounded on purpose. It may not edit
`inst/extdata/database-source/*.tsv`, may not bump `database_release.tsv`, and
may not create a GIFT. A screen inverts the curation order — it starts from an
accession that happens to be specific rather than from a capability worth
inferring from a genome — and invariants 3 and 9 are the guardrails against
where that leads: no new anchor unless it is a real boundary, and no arbitrary
single-step fragments. A candidate that would need a new anchor goes into the
register with that stated, not into a recommendation.

Three rules bound every verdict below.

- **The equivalog grade is necessary and not sufficient.** In database
  2026.23.1, four profiles that passed the grade filter were refused on biology
  after being read: a deferrochelatase sharing an EC with the ferrochelatase it
  runs backwards from, an esterase NCBIfam says is distinct from MetX, a model
  that withdraws its own one-function guarantee, and an "alternative type"
  protein. That is roughly one profile in fourteen. Every candidate's `comment`
  and `product_name` was read here, and §5.3 records a refusal reached that way
  and no other.
- **Invariant 16 still bounds everything.** A profile that resolves a *protein*
  does not thereby resolve a *substrate*. The ring-hydroxylating dioxygenase
  refusals are the standing example and nothing in NCBIfam touches them.
- **The grade filter is not widened.** `equivalog` and `equivalog_domain` are
  the admission rule. §6.1 records what that costs and refuses to pay less.

## 2. Method: two joins, and what each can say

The screen composes two joins on opposite sides of the profile.

```text
join 1   NCBIfam profile --(ec_numbers)--> EC --(Rhea)--> master reaction
join 2   NCBIfam profile --(product_name, gene_symbol)--> anchor name
```

Join 1 states chemistry and is what the namespace was assessed on. Join 2 states
nothing but a string, and it exists because join 1 is blind to two thirds of the
namespace (§5.1). Where the two disagree, join 1 wins; where join 1 is silent,
join 2 produces a reading queue and never a verdict.

Both joins run only on the two equivalog grades. Of the 38,394 profiles in
release 20.0, **13,888** are `equivalog` (13,583) or `equivalog_domain` (305) —
recomputed here, matching the figure in the admission assessment.

## 3. Stream 1 — three register rows that were already a bounded lookup

Three rows in [section 1 of the register](deferral-register.md) name NCBIfam
explicitly as what would settle them, with the decision criterion already
written. Each asks one question: **does an equivalog-grade profile in
`hmm_PGAP/20.0` cover the chemistry at the specificity the trait's name
claims?**

| Row | Answer | Verdict |
|---|---|---|
| Macrolide esterase *ereA* | No, and not for want of a profile | **Refused. NCBIfam retrigger closed** |
| Caffeine N-demethylation | No — no profile exists at any grade | **Deferred, restated. NCBIfam retrigger closed** |
| Polyhydroxybutyrate biosynthesis | No — every PHA synthase profile is `subfamily`-graded, and its classes are not substrate classes | **Deferred, restated. NCBIfam retrigger closed** |

All three answers are negative, and that is the point of asking. A "no" with its
evidence closes the question for the next reader; leaving the row open does not.

### 3.1 Macrolide esterase *ereA* — the profile exists and is the wrong grade

The register row said the block was "no KO exists" and that NCBIfam had made
this a lookup rather than a namespace decision. The lookup returns four facts.

| Profile | Grade | Hits | What it is |
|---|---|---:|---|
| `NF000208.1` *ere(A)* | `exception` | 21 | EreA family erythromycin esterase |
| `NF000209.1` *ere(B)* | `exception` | 3 | EreB family erythromycin esterase |
| `NF000516.1` *ere(D)* | `equivalog` | 21 | EreD family erythromycin esterase |
| `NF016994.7` | `domain` | 41,370 | erythromycin esterase family protein |

*ereA* itself is graded `exception`, which the admission rule refuses. That is
not an accident of this one profile: 1,392 profiles carry the `exception` grade
and 668 of them are AMRFinder models, so NCBIfam's antimicrobial-resistance
layer is *systematically* outside the equivalog filter. §6.1 records that as a
standing consequence rather than as a fact about *ereA*.

The interesting half is what the equivalogs that do exist actually say. Three
macrolide esterases pass the grade filter — `NF052610.1` *mle* (2,255 hits),
`NF041759.1` *estT* (158) and `NF033124.1` *estX* (167) — and NCBIfam's own
comments split them by ring size, not by drug:

> The founding member of this family … was shown to hydrolyze macrolides with
> 16-atom lactone ring structures, such as tylosin, tilmicosin, and
> tildipirosin, **but not** macrolides such as erythromycin, tulathromycin,
> gamithromycin with 14- or 15-atom rings.
> — `NF041759.1` *estT*

So the equivalog layer resolves macrolide lactone hydrolysis and places
erythromycin on the side it does not cover. `NF000516.1` *ere(D)* is the one
equivalog that names erythromycin, and it is a different family from EreA at 21
RefSeq hits.

**Verdict: refused, and the NCBIfam retrigger is closed.** A trait named for
*ereA*, or for erythromycin, cannot be evidenced: the accession that names it is
refused on grade, and the accessions that pass the grade name a different ring
size. The remedy the architecture prescribes — name the broader claim the
evidence supports — is available: `NF052610.1` would evidence *macrolide ester
hydrolysis* as chemistry. That is a different trait from the one the register
row asked about, it belongs beside the detoxification GIFTs in
[the antimicrobial proposal](proposal-antimicrobial-detoxification.md) which are
not curated, and it is recorded as a new register row rather than adopted here.

### 3.2 Caffeine N-demethylation — nothing at any grade

[The aromatic proposal](proposal-aromatic-degradation.md) §9.3 refused caffeine
on availability rather than specificity: NdmA, NdmB and NdmC are regiospecific
Rieske monooxygenases, Rhea covers all three reactions cleanly, and the refusal
turned entirely on the NdmD reductase having no accession. Its re-test condition
named this namespace: *"revisit when NdmD receives a KO or when an NCBIfam
family covers the ndm reductase."*

Release 20.0 contains no profile whose `gene_symbol` begins `ndm`, none whose
`product_name` names caffeine, theobromine, paraxanthine, a methylxanthine or
trimethyluric acid, and none for the alternative caffeine dehydrogenase
*cdhABC*. The only profile in the release mentioning caffeine at all does so in
a comment about an unrelated methyltransferase.

**Verdict: deferred, restated.** The refusal is unchanged and its NCBIfam
retrigger is closed. The row now says what was checked, so the next reader does
not repeat the search.

### 3.3 Polyhydroxybutyrate — the classes are not substrate classes

[The compatible solutes proposal](proposal-compatible-solutes-heme-enterobactin-detoxification.md)
§8 refused PHB because `K03821` names PHA synthases across substrate classes and
cannot identify PHB, and set the retrigger as *"a validated class/subfamily
marker whose members accept (R)-3-hydroxybutyryl-CoA."*

NCBIfam grades every PHA synthase below the admission threshold:

| Profile | Grade | Hits | What it is |
|---|---|---:|---|
| `TIGR01838.1` *phaC* | `subfamily` | 20,627 | class I poly(R)-hydroxyalkanoic acid synthase |
| `TIGR01839.1` *phaC* | `subfamily` | 5,484 | class II poly(R)-hydroxyalkanoic acid synthase |
| `TIGR01836.1` *phaC* | `subfamily` | 3,698 | class III synthase subunit PhaC |
| `TIGR01834.1` *phaE* | `subfamily` | 1,992 | class III synthase subunit PhaE |
| `NF018827.7`, `NF023965.7` | `domain` | 42,457, 6,866 | PhaC polymerase domain fragments |

The grade refusal is decisive on its own, but it is not the strongest reason to
say no, and the stronger reason survives any future re-grading. **The PhaC
classes are structural classes of the polymerase, not monomer classes.** Class I
and class III make short-chain-length polyester and class II makes
medium-chain-length, and within short-chain-length nothing in the class
separates 3-hydroxybutyrate from 3-hydroxyvalerate. A class marker therefore
answers a different question from the one the trait's name asks, which is
exactly invariant 16.

Two profiles in the same operon *do* pass the grade filter — `NF042967.1` *phaA*
(EC 2.3.1.9, 138 hits) and `NF042966.1` *phaB* (EC 1.1.1.36, 125 hits) — and
they supply (R)-3-hydroxybutanoyl-CoA. They change nothing. The original refusal
already anticipated this: pairing monomer supply with a broad polymerase does
not prove that the polymerase accepts that monomer, and *"the current refusal
must not be bypassed by pairing K03821 with upstream enzymes."* It must not be
bypassed by pairing `TIGR01838.1` with them either.

**Verdict: deferred, restated.** The NCBIfam retrigger is closed; the retrigger
that remains is monomer-resolving evidence of a kind no namespace currently
offers.

## 4. Stream 2 — subunit resolution, which is what the namespace is for

### 4.1 The recomputed figures, and the rule that produced them

An EC is a candidate when **two or more equivalog-grade profiles carry that
complete EC and their `product_name`s use subunit language** — `subunit`,
`chain`, `component`, a Greek letter, `large` or `small`.

| Quantity | Value |
|---|---:|
| Equivalog profiles carrying at least one complete EC | 4,623 |
| ECs meeting the candidate rule | **169** |
| of those, reaching a Rhea master gifter curates | **31** |
| of those, genuinely naming two or more distinct subunits after reading | **23** |

The last row is the one that matters and it is why the rule is stated rather
than trusted. Eight of the 31 are artefacts of chemical nomenclature: the string
`gamma` inside *N-acetyl-**gamma**-glutamyl-phosphate reductase*, *cystathionine
**gamma**-synthase* and *methionine **gamma**-lyase*; `beta` inside *pantoate--
**beta**-alanine ligase*; `chain` inside *branched-**chain** amino acid
transaminase*; and `component I` in three names where no component II exists as
a separate profile. A screen that reported 31 would be reporting eight enzymes
that have one subunit.

### 4.2 The shared-accession audit, re-run and confirmed

The first failure mode — one accession standing in for two jointly required
components — was audited across the entire shipped catalogue, not only the
candidate ECs: 1,379 `component_markers` rows over 502 enzyme systems.

**Exactly one system shares an accession across its own components**, and it is
correct:

| System | Reaction | Accession | Components |
|---|---|---|---|
| `SYS_20557_UREABC` | `RHEA:20557` urease | `KO:K14048` | `COMP_20557_BETA`, `COMP_20557_GAMMA` |

`K14048` is KEGG's *ureAB*, the genuine gamma–beta fusion. One gene legitimately
satisfies both components, and gifter's AND logic is right to let it: a genome
carrying the fused protein does encode both subunits. This is a fusion, not a
defect, and treating it as one would break the very lineages the row exists for.

Four further accessions appear on two components of the same *reaction* through
two *different* systems — `K00382` and `K00627` across the two PDH systems,
`K00957` across the two sulfurylase systems, `K23265` across the dimeric and
trimeric FGAM synthases. All four are the same subunit appearing in two
alternative implementations of one reaction, which is what the system layer is
for.

**One repair is owed and is not made here.** The two `K14048` rows carry an
empty `notes` field, so the fusion argument that makes them correct lives
nowhere in the database. A reader auditing for exactly this failure mode finds
the shape of a defect with no rationale beside it. Writing those notes edits
`component_markers.tsv`, which this pass may not do; it is recorded in the
register as a curation-hygiene row and belongs in the next release that touches
the source tables.

### 4.3 The named candidates: no repair, and one new capability

The five systems named as the places to look first were read individually.

| EC | Enzyme | NCBIfam names | gifter evidences | Verdict |
|---|---|---|---|---|
| 1.14.12.1 | anthranilate 1,2-dioxygenase | AntAB and AndAcAd, 4 profiles | two systems, one accession per subunit (`K05599`/`K05600`, `K16319`/`K16320`) | **No gain** |
| 1.14.12.10 | benzoate 1,2-dioxygenase | BenA, BenB | `K05549`, `K05550` | **No gain** on the oxygenase; see §4.5 for BenC |
| 1.14.13.149 | phenylacetyl-CoA epoxidase | PaaB, PaaC, PaaD, PaaE | all five of PaaA–PaaE, one KO each | **No gain** |
| 1.14.13.251 | glycine betaine monooxygenase | GbcA, GbcB | `K00479`, `K21832` | **No gain** |
| 1.18.6.1 | nitrogenase | NifDK, VnfDKG, AnfDKG — 8 profiles | Mo and V routes fully resolved; **Fe-only absent** | **New capability, still blocked — §4.4** |

Four of the five are negative, and that is the honest answer: gifter already
evidences each jointly required component with its own accession, so NCBIfam
would add annotation coverage rather than resolution. The exception is
nitrogenase, and it is the largest finding in this assessment.

### 4.4 Fe-only nitrogenase — a prose refusal whose retrigger has half fired

`gifts.tsv` records, in the `notes` column of `nitrogen_fixation`:

> The Fe-only architecture is deferred because current KO groups do not separate
> AnfHDK from NifHDK while the minimum native assembly requirement remains
> context-dependent.

**That refusal had no register row.** It is exactly the failure mode the
register's own coverage note warns about — a refusal that lives in prose and is
found again only by accident — and it is now recorded.

Half of it is no longer true. NCBIfam separates the Fe-only structural subunits
at equivalog grade, and KEGG does not:

| Subunit | NCBIfam | KEGG | Comment evidence |
|---|---|---|---|
| AnfD | `TIGR01861.1`, equivalog, 329 hits | none | "the all-iron variant of the nitrogenase component I alpha chain" |
| AnfK | `TIGR02931.1`, equivalog, 326 hits | none | "the beta subunit of the iron-only alternative nitrogenase" |
| AnfG | `TIGR02929.1`, equivalog, 303 hits | `K00531` | "the delta subunit of the Fe-only alternative nitrogenase" |
| AnfO | `TIGR02940.1`, equivalog, 258 hits | none | "found only in species with the Fe-only nitrogenase" |
| **AnfH** | **none** | **none** | — |

Two things still block the route, and both are stated so the next pass does not
rediscover them.

- **The electron-delivery component has no subunit-resolving accession
  anywhere.** `TIGR01287.1` *nifH* says so itself: *"This model includes
  molybdenum-iron nitrogenase reductase (nifH), vanadium-iron nitrogenase
  reductase (vnfH), and iron-iron nitrogenase reductase (anfH)."* It is the
  flagellar-stator case in a different enzyme, and admitting it on an AnfH
  component would let the Mo iron protein satisfy the Fe-only architecture.
  gifter's own note on `COMP_21448_NIFH` already says "NifH alone is not
  evidence of a complete nitrogenase"; this would make it worse. **Refused.**
- **The reaction has no Rhea master.** Rhea covers EC 1.18.6.1 as `RHEA:21448`,
  the molybdenum reaction, and EC 1.18.6.2 as `RHEA:55540`, the vanadium one.
  NCBIfam assigns AnfD and AnfK EC 1.18.6.1 by inheritance, but the Fe-only
  enzyme is not the molybdenum reaction — it evolves substantially more hydrogen
  per dinitrogen, which is precisely why the vanadium route needed its own Rhea
  entry rather than sharing the molybdenum one — curated as `RHEA:55543`, which
  §4.6 shows is not quite the right identifier for it. Curating the
  Fe-only system on `RHEA:21448` would state a stoichiometry the enzyme does not
  perform.

**Verdict: deferred, with a sharpened blocker.** All three component I subunits
are now separable; component II and the reaction are not. Recorded in register
section 1, and the `nitrogen_fixation` notes should be re-stated when the source
tables are next touched, because as written they are now half false.

Checking the vanadium comparison turned up something small and separate, and
§4.6 records it.

### 4.5 Two more readings from the same 23

**2026-10-04 update.** The `K01752` assignment question below was resolved:
KEGG assigns it to both *B. subtilis* split chains as well as complete
single-chain proteins. Database 2026.37.1 retires it as completing evidence
and adds architecture-specific systems. The audit and call limits are in
[the serine-deamination revision](assessment-serine-deamination-revision.md).
The paragraphs below preserve the original discovery-stage reasoning.

**A new alternative enzyme system that is ready to curate.** EC 4.3.1.17,
`RHEA:19169`, L-serine ammonia-lyase, inside `serine_deamination`. gifter
evidences the reaction with **one** component, `COMP_19169_CATALYTIC`, carrying
`K01752` (*sdaA*/*sdaB*/*tdcG*, the single-chain form) and `K17989` (the
eukaryotic PLP-dependent SDS/CHA1). NCBIfam names two:

| Profile | Grade | Hits | Product |
|---|---|---:|---|
| `TIGR00718.1` *sdaAA* | equivalog | 15,278 | L-serine ammonia-lyase, iron-sulfur-dependent, subunit alpha |
| `TIGR00719.1` *sdaAB* | equivalog | 12,514 | L-serine ammonia-lyase, iron-sulfur-dependent, subunit beta |

Both comments say the same thing and it is the Ahb shape exactly: *"A fairly
deep split in a UPGMA tree separates members of this family of alpha chains from
the homologous region of single chain forms such as found in Escherichia coli."*
The split form is a genuinely two-gene enzyme, distinct from the fused form
gifter already evidences, and at ~15,000 and ~12,500 RefSeq hits it is not rare.

This is **ready to curate**: the reaction, the route and both anchors already
exist, no new anchor is needed, the two accessions are equivalog with clean
comments naming distinct subunits, and the shape is a second enzyme system on an
existing reaction with two jointly required components. It is deliberately not
curated here. Adding an alternative system is a `broadens` change — genomes
carrying the split enzyme and neither `K01752` nor `K17989` would begin
completing `serine_deamination` — and that is the next release's decision, with
its own `database_changes.tsv` entry.

**One question was left unresolved and the curator should settle it first.**
KEGG defines `K01752` by the single-chain genes *sdaA*, *sdaB* and *tdcG*, but
whether it is also *assigned* to the halves of the split enzyme in annotated
genomes cannot be read from `list/ko` and was not checked here. The answer does
not change the verdict above — an alternative system is OR at the reaction
layer, so adding it broadens either way — but it decides whether a **second**,
narrowing decision is owed. If `K01752` does annotate the split halves, then
`serine_deamination` completes today on a genome carrying the alpha chain alone,
which is a live over-call that the new system does not repair. If it does not,
gifter simply under-calls the split lineages and the new system is the whole
fix.

**Two curated dioxygenase systems are missing their electron-transfer
components, and only one of them is a namespace question.** Class IB
ring-hydroxylating dioxygenases cannot turn over without a reductase, and
`SYS_12633_BENAB` and both anthranilate systems curate the oxygenase alone.
`SYS_20357_HCAEF` is the same. The evidence position differs per system:

| System | Reductase | KEGG | NCBIfam |
|---|---|---|---|
| benzoate `SYS_12633_BENAB` | BenC | **none** | `NF040810.1`, equivalog, 10,067 hits |
| anthranilate `SYS_11072_ANTAB` | AntC | `K11311` | — |
| anthranilate `SYS_11072_ANDA` | AndAa | `K18249` | `NF041682.1`, equivalog |
| phenylpropanoate `SYS_20357_HCAEF` | HcaC, HcaD | `K05710`, `K00529` | `NF007422.0`, `NF042949.2` |

Only benzoate depends on the namespace; for the other three the accession has
been available in KEGG all along. All four are recorded together because they
raise one question, and it is not a marker question: **does a gifter enzyme
system require the reductase of a multicomponent oxygenase?** Today four systems
say no while [the aromatic proposal](proposal-aromatic-degradation.md) §9.3
refuses caffeine on the grounds that its system would be "missing its reductase
component" — the two positions cannot both be right. Adding the component is a
`narrows` change and needs its own decision; it is deferred to the register with
the inconsistency named.

### 4.6 Three curated reactions are keyed by a bidirectional ID, not a master

Not an NCBIfam finding: the vanadium nitrogenase comparison in §4.4 needed
`reactions.tsv` checked against Rhea's own direction table, and three of the 419
curated `rhea_master` values turn out not to be masters.

| Curated as | Actually the bidirectional form of | Reaction | GIFT |
|---|---|---|---|
| `RHEA:55543` | `RHEA:55540` | vanadium nitrogenase | `nitrogen_fixation` |
| `RHEA:18136` | `RHEA:18133` | sulfate adenylyltransferase | `assimilatory_sulfate_reduction` |
| `RHEA:13804` | `RHEA:13801` | NADPH sulfite reductase | `assimilatory_sulfate_reduction` |

Invariant 4 says a reaction is identified by the Rhea master ID and stores
direction separately in the route, so a bidirectional child in that column
states direction twice and in two places. The practical cost is why it is worth
a row rather than a shrug: **both specificity screens key on masters, so these
three reactions are silently outside every measurement either screen makes.**
They are not reported as broad, or as narrow, or as unscreened — they simply do
not join. `RHEA:18136` is also one of the four accessions in §4.2's cross-system
audit, and it appeared there only because that audit matches reaction IDs
directly rather than through the EC join.

Correcting them edits `reactions.tsv` and moves foreign keys, so it is not done
here. Deferred to the register.

## 5. Stream 3 — the blind spot, and a discovery product for it

### 5.1 The measurement

The EC join is blind to most of the namespace, and the screen now says so:

| Class | Profiles |
|---|---:|
| No EC number at all | **8,711** |
| Only an incomplete EC (`1.14.-.-`) | 554 |
| Complete EC reaching no Rhea master | **385** |
| **Invisible to the EC join** | **9,650 of 13,888** |

`TIGR04546.1` *ahbC* sits in the first group. The route the namespace was
admitted for is three steps long, and the EC join would have found two of them.

### 5.2 The second join, and its validation

`ncbifam_equivalog_screen.R` now emits
`data-raw/reference/ncbifam-discovery-candidates.tsv`, built by matching
declared-anchor names against `product_name` and `gene_symbol`. Three properties
of the match are deliberate and are argued in the script:

- **Left-permissive, right-anchored.** Chemical names compose by prefixing, so
  `siroheme` must match `12,18-didecarboxysiroheme`, which a word-boundary match
  misses. This is not a detail: it is the single rule that decides whether the
  screen finds *ahbC*.
- **Subsumption.** A term that is a proper suffix of a longer term matched on
  the same profile is dropped, so a homocysteine methyltransferase does not also
  read as a cysteine candidate. 109 rows dropped.
- **Protein context marked, not deleted.** `histidine kinase` is the largest
  false positive in the raw match and has nothing to do with histidine. 163 rows
  are marked `protein context, not the free metabolite` and kept in the file,
  because a suppressed match nobody can re-read is indistinguishable from one
  that was never made.

| Stage | Count |
|---|---:|
| Anchors with a searchable term of five characters or more | 153 of 156 |
| Raw name matches | 1,169 rows over 916 profiles |
| Rows kept after subsumption | 1,060 |
| of those, marked `protein context` | 163 |
| of those, marked `already a curated marker` | 1 |
| Rows surviving the anchor join | 896 |
| **Profiles surviving the anchor join** | **772** |
| touching an anchor of Rhea degree ≤ 50 | 331 |
| touching an anchor of Rhea degree ≤ 20 | 130 |

Anchor hub degree is computed from Rhea exactly as
`marker_specificity_screen.R` computes it, so the two discovery queues rank by
the same measurement and can be read together. `GTP`, `NAD` and `UREA` have no
term of five characters and are unsearchable by name; the run log says so, so
the blind spot of the blind-spot screen is visible too.

**The method check is that the screen rediscovers *ahbC*.** `TIGR04546.1` comes
back on the `SIROHEME` anchor at Rhea degree 2, flagged `already a curated
marker`. The product that would have found the third step of the Ahb route now
exists, two days after the route was curated without it.

**What this join is not.** The KO screen reaches an anchor through a reaction's
ChEBI participants and therefore states chemistry. A string inside a product
name states nothing at all. Every row needs its `comment` and `product_name`
read before it is anything, and the file carries the `comment` column for that
reason.

### 5.3 What survived the reading

The queue was read from the top of the ranking down. Four candidates are worth
a decision; the remaining 768 profiles are a queue and not one.

| Candidate | Anchors | Verdict |
|---|---|---|
| Stickland reductases on glycine, sarcosine and betaine (`grdABCDE`, `grdFG`, `grdHI`) | `GLYCINE`, `SARCOSINE`, `BETAINE`, `ACETYL_PHOSPHATE` | **Deferred** — a real uncurated capability, but KO-evidenced, not NCBIfam-unblocked |
| Ectoine utilization `eutABC` | `ECTOINE` | **Refused** — predicted function, and the profile's own comment names the wrong protein |
| Hydroxyectoine utilization dehydratase `NF005680.0` *eutB* | `HYDROXYECTOINE` | **Deferred** — no reaction, and a single-step fragment off an output-only anchor |
| Benzoate dioxygenase reductase `NF040810.1` *benC* | `BENZOATE` | **Deferred** with §4.5, as one question about four systems |

**The Stickland reductases.** `NF040746.1` *grdC*, `NF040747.1` *grdD* and
`NF040748.1` *grdA* surfaced on three anchors at once, and their comments
immediately say why they cannot carry a claim on any of them: *"Protein C is the
shared acetyl-phosphate-forming component of three types of selenoprotein-
containing complexes, acting on glycine, sarcosine, or betaine. A different
subunit, B, determines the substrate."* That is invariant 16 stated by the
resource itself, and it is the same shape as the flagellar stator.

The substrate-determining B subunits split cleanly by namespace, and the split
is instructive:

| Substrate | KEGG | NCBIfam |
|---|---|---|
| glycine | `K10671` *grdE*, `K10672` *grdB* | `TIGR01917.1` *grdB*, **equivalog** |
| sarcosine | `K21583` *grdG*, `K21584` *grdF* | `NF040793.1`, `NF040794.1`, **`exception`** |
| betaine | `K21578` *grdI*, `K21579` *grdH* | `NF040795.1`, **`exception`** |

`TIGR01917.1` is a good marker and says so — *"Closely related to it, but
excluded from this model, are selenoprotein B subunits of betaine reductase and
sarcosine reductase."* But KEGG resolves all three substrates and NCBIfam
resolves one, so this capability is not blocked on the namespace and never was.
Rhea covers the chemistry (`RHEA:12232`, `RHEA:12825`, `RHEA:11848`), every
anchor it needs already exists, and `proline_reduction_stickland` is the curated
sibling that shows the shape works. `discovery-candidates.tsv` from the KO
screen already listed `K21578`, `K21579`, `K21583` and `K21584` on
`ACETYL_PHOSPHATE`; nobody acted on it. **Deferred to the register as a
capability worth its own proposal, explicitly not an NCBIfam retrigger.**

**Ectoine utilization is refused, and only reading the comments gets there.**
`TIGR02990.1` *eutA* and `TIGR02992.1` *eutC* both pass the grade filter and
both fail on their own text. `TIGR02990.1` describes *"a **predicted**
arylmalonate decarboxylase"* and adds that it *"is missing from two other
species with the other ectoine transport and utilization genes"* — a family that
is absent from organisms that perform the capability cannot be a required
component of it. `TIGR02992.1` is worse: its accession, gene symbol and product
name say EutC, and its comment begins *"Members of this protein family are
EutA"*. The description was copied and not corrected, so the model's own
statement of what it recognises contradicts its label. Neither carries an EC,
neither reaches a reaction, and the function is predicted rather than
characterised. **Refused on biology, exactly as the four profiles in the
admission release were.**

**Hydroxyectoine utilization is deferred on shape, not on evidence.**
`NF005680.0` *eutB*, "hydroxyectoine utilization dehydratase", is equivalog with
5,040 RefSeq hits and an empty comment. It is attractive because
`HYDROXYECTOINE` is currently an output-only anchor — `hydroxyectoine_biosynthesis`
produces it and nothing consumes it, the same shape as the chitosan deferral in
[anchor fates](proposal-anchor-fates.md) §5.2. Three things stop it: the profile
carries no EC and no Rhea master, so invariant 4 would need a cross-reference
nobody has read; its function assignment is unread, which after §5.3's other
ectoine profiles is not a formality; and hydroxyectoine to ectoine is one step
handing straight to the existing `ectoine_degradation`, which is the arbitrary
single-step fragment invariant 9 refuses. **Deferred with all three stated.**

## 6. Refusals and standing consequences

### 6.1 The grade filter is not widened, and this is what that costs

229 profiles reach a curated reaction and are refused on grade alone. The screen
writes them to `ncbifam-grade-refusals.tsv` and a test asserts that none is ever
a marker. Their grades:

| Grade | Profiles |
|---|---:|
| `subfamily` | 131 |
| `exception` | 45 |
| `domain` | 27 |
| `PfamEq` | 22 |
| `hypoth_equivalog` | 2 |
| `subfamily_domain` | 2 |

The `exception` row has a consequence this pass discovered and the register did
not previously hold. Across the whole release, 1,392 profiles are graded
`exception` and 668 of them are AMRFinder models — allele- and family-level
resistance profiles. **NCBIfam's antimicrobial-resistance content is therefore
almost entirely outside gifter's admission rule**, and
[the antimicrobial detoxification proposal](proposal-antimicrobial-detoxification.md)
cannot be evidenced from this namespace under the current filter. That is a real
cost and it is the right one to pay: an `exception` model is built to recognise
a named resistance allele, not to assert that a family shares one function, and
the grade is the resource's own statement of that. Widening the filter is a
separate architectural decision with its own release, not a side effect of
wanting a particular trait. Recorded in the register.

### 6.2 What was refused, with its evidence

| Refused | Evidence |
|---|---|
| A trait named for *ereA* or for erythromycin esterase | `NF000208.1` is `exception`-graded; the equivalogs that pass name 16-membered macrolides and `NF041759.1` says explicitly that it does not hydrolyse erythromycin |
| PHA synthase class markers as PHB evidence | Every PhaC profile is `subfamily` or `domain`; and the classes separate chain length, not monomer, so re-grading would not help |
| `TIGR01287.1` *nifH* as evidence for an AnfH component | The model states that it includes *nifH*, *vnfH* and *anfH*; admitting it would let the molybdenum iron protein satisfy the Fe-only architecture |
| `TIGR02990.1` *eutA*, `TIGR02992.1` *eutC* | Predicted function; EutA is absent from species that perform the capability; EutC's comment describes EutA |
| Widening the grade filter to reach the AMR layer | §6.1 |

## 7. What changed in the repository

Nothing biological. Specifically:

- `data-raw/ncbifam_equivalog_screen.R` gains the discovery section and two
  cached Rhea inputs it needs for anchor hub degree. Recorded in `CHANGELOG.md`.
- `data-raw/reference/ncbifam-discovery-candidates.tsv` is new and committed,
  documented in `data-raw/reference/README.md`.
- [The deferral register](deferral-register.md) gains nine rows in section 1 and
  one in section 3: the Fe-only nitrogenase architecture, the split serine
  ammonia-lyase, the Stickland reductases, hydroxyectoine utilization, the
  ectoine utilization refusal, the macrolide chemistry claim, the
  `exception`-grade consequence for the AMR layer, the three bidirectional Rhea
  identifiers, the missing `K14048` rationale, and the multicomponent-oxygenase
  reductase question. It closes the NCBIfam retrigger on the *ereA*, caffeine
  and PHB rows, and gains a note that a refusal can also hide in a `notes`
  column of a source table.
- `inst/doc/architecture.md` points at this assessment from the marker
  namespace paragraph, and names the `exception`-grade consequence there,
  because that is the paragraph a curator reads before admitting an NCBIfam
  accession.
- No `database_changes.tsv` entry, no `database_release.tsv` bump, no source
  table edited. The database still states 2026.24.1.

## 8. Retrigger

Re-run and re-read this assessment when:

- a new NCBIfam release is pinned — which is a marker-layer migration, and the
  curated rows must be re-read, not only the screen re-run;
- the grade filter is widened by an explicit architectural decision, at which
  point §6.1 and every row in `ncbifam-grade-refusals.tsv` need re-reading;
- Rhea adds a master for the Fe-only nitrogenase reaction, or any namespace
  produces an AnfH-specific profile;
- a decision is taken on whether an enzyme system must require the reductase of
  a multicomponent oxygenase (§4.5);
- the anchor vocabulary changes, since the discovery join is built from it.

```sh
Rscript data-raw/ncbifam_equivalog_screen.R --offline
```
