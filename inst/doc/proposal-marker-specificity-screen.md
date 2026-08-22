# Assessment: a computable specificity screen for the KO marker layer

Status: **assessed 2026-08-22.** The screen is implemented as a curation tool
and its three derived tables are kept as reference inputs. **No GIFT, marker,
route, schema table or runtime behaviour changed.** The curated marker layer was
audited against the screen and no route was found whose claim exceeds its
evidence.

**Decision timestamp:** 2026-08-22T17:25Z

**Inputs:** Rhea release 141 (2026-06-10); KEGG orthology as of 2026/08/22,
28,436 entries; gifter database source at 2026.21.x.

**Tool:** `data-raw/marker_specificity_screen.R`

---

## 1. The question

Invariant 16 says the specificity of a GIFT claim must not exceed the
specificity of its genomic evidence. Every proposal in this directory applies it
by hand, one accession at a time: the pseudolysin refusal in
[protein degradation](proposal-protein-degradation.md), the nine aromatic
refusals in [aromatic degradation](proposal-aromatic-degradation.md), the
AhbA/AhbB refusal in [the MetaCyc pass](proposal-metacyc-expansion.md), the
`K22225` heterodimer problem, the flagellar coupling-ion refusal. Each is
correct and each cost a curator a separate investigation.

For the KO namespace the underlying measurement is computable, because two
public mappings compose:

```text
KO --(KEGG)--> EC --(Rhea)--> Rhea master reaction --> ChEBI participants
```

A KO whose ECs reach exactly one Rhea master states one reaction. A KO reaching
several states only their union. That is the whole screen.

The question this assessment answers is whether that measurement is worth
having: does it reproduce the refusals already reached by hand, does it find
anything in the curated layer that should not be there, and does it point at
work worth doing.

## 2. What the screen does and does not establish

This matters more than the counts, because the screen is easy to over-read.

A marker reaching several reactions is broad in one of two ways, and public
mappings cannot separate them:

- **Ambiguous ortholog.** The KO groups genes with different activities. The
  evidence cannot say which reaction a matched gene performs, and a
  substrate-specific claim built on it is unsupportable. This is the invariant
  16 failure.
- **Promiscuous enzyme.** The KO groups genes for one protein that genuinely
  catalyses several reactions. The evidence does support each of them, including
  the curated one. This is not a failure, and narrowing the marker would be
  wrong.

`K00826` is the clean illustration. Branched-chain aminotransferase reaches
three masters — the valine, leucine and isoleucine transaminations — because
IlvE performs all three. A genome carrying it encodes the 2-oxoisovalerate to
L-valine conversion that `valine_biosynthesis` claims. The breadth is the
enzyme's, not the annotation's.

So the screen is a **question generator with a bounded scope**, not a verdict
generator. It is also namespace-bounded: it says nothing about CAZy, Pfam,
TIGRFAM or bare EC markers, and reports reactions evidenced by those as *not
screened* rather than as unsupported. Nothing here licenses removing a marker
without reading the biology.

## 3. Method

`data-raw/marker_specificity_screen.R` fetches five public files into an
uncommitted cache and joins them against the database source. KO to EC is the
union of KEGG's `link/enzyme/ko` and the ECs bracketed in the orthology names,
which disagree at the margins; incomplete ECs such as `1.14.-.-` are dropped
because a partial EC cannot resolve to a reaction.

Four verdicts are assigned to each EC-bearing KO:

| Verdict | Meaning | Count |
|---|---|---:|
| `single_reaction` | one Rhea master; can carry a substrate-specific claim | 5,354 |
| `multi_reaction_one_ec` | several masters under one EC — substrate range of one activity | 1,530 |
| `multi_reaction_multi_ec` | several ECs — bifunctional protein, or an ortholog defined too loosely | 788 |
| `ec_without_rhea` | complete EC, no Rhea coverage | 1,435 |
| `partial_ec_only` | only incomplete ECs | 2,017 |

Two further quantities make the output readable. For a multi-reaction marker,
**varying participants** lists the ChEBI names that are not shared by all of its
masters — the difference between "quinone versus menaquinone" and "galactose
versus xylose" is then visible without opening Rhea. For discovery, the **Rhea
degree** of each ChEBI, its count of master reactions across the whole database,
separates a boundary molecule from a hub without anyone hand-writing a list of
currency metabolites, which would itself be a biological claim. Ammonium and
L-glutamate are declared gifter anchors *and* appear in thousands of reactions;
the degree says so, and the ranking demotes them.

## 4. Audit of the curated layer

785 curated KO marker rows, 656 distinct accessions.

| Observation | Rows |
|---|---:|
| Sole marker of its component and reaching more than one reaction | 159 |
| Evidence link not corroborated by the public KO→EC→Rhea mapping | 62 |
| Marker carries no complete EC, so the screen cannot place it | 38 |

The per-marker flag is the wrong altitude, and the audit says so. A claim
belongs to a route, not to one accession: galactose mutarotase acts on several
aldoses, but the Leloir route also requires a galactokinase and a
galactose-1-phosphate uridylyltransferase, and those pin the substrate. The
route-level reading is the one that matters:

| Route-level state | Routes |
|---|---:|
| Screened | 204 |
| No required reaction evidenced by a single-reaction KO | 23 |
| At least one required reaction evidenced only outside the KO namespace | 5 |
| Broad KO alongside evidence this screen does not cover | 8 |

**All 23 were read individually. None is an invariant 16 failure.** They fall
into four groups:

- **Cofactor or acceptor variation.** `succinate_fumarate_interconversion`,
  `homoserine_biosynthesis`, `oxoglutarate_to_succinate`. The SDH and FRD
  subunits reach four masters that differ only in ubiquinone, menaquinone,
  rhodoquinone or the generic quinone; homoserine dehydrogenase reaches two that
  differ only in NAD versus NADP. The substrate is identical in every one. This
  is exactly the case the `oxygen_requirement` and quinone-agnostic curation
  already assumes.
- **Genuine promiscuity of one protein.** `valine_biosynthesis` and
  `isoleucine_biosynthesis` through IlvE; `oxoisovalerate_biosynthesis` through
  the shared IlvBCD chemistry of the valine and isoleucine branches;
  `serine_biosynthesis` through the D- and L-phosphoserine phosphatases;
  `propanediol_formation` through the (R)- and (S)-lactaldehyde reductase;
  `glycine_biosynthesis` through SHMT, which also cleaves threonine and
  hydroxytrimethyllysine; `methionine_biosynthesis_sulfhydrylation` through
  MetX and MetA, which acylate homoserine with either acetyl-CoA or
  succinyl-CoA, and through `K17069`, which sulfhydrylates O-acetylhomoserine
  and O-acetylserine alike;
  `carnitine_degradation_trimethylamine` through the NADH and NADPH forms of
  carnitine monooxygenase. In each the declared anchors state which of the
  enzyme's reactions the GIFT is about, and the enzyme performs it.

  `K17069` deserves a note, because it is the shape invariant 16 warns about:
  one accession that is evidence for two neighbouring GIFTs,
  `methionine_biosynthesis_sulfhydrylation` and `cysteine_biosynthesis_sulfide`.
  Here it is admissible, because MET17 genuinely catalyses both reactions rather
  than being an ortholog that cannot tell them apart. The distinction is the one
  in section 2, and it is why this row is a question and not a defect.
- **A master and its own sub-step.** `enterobactin_biosynthesis` and
  `thiamine_phosphate_biosynthesis`. EntB, EntD, EntE and EntF each reach both
  the overall assembly master and the partial reaction they individually
  catalyse; ThiE and ThiD reach the thiamine-phosphate condensation together
  with the carboxy-thiazole variants of the same condensation. The fan-out is
  Rhea recording the same chemistry at two granularities, and both belong to the
  curated capability.
- **Deliberately broad claims already argued elsewhere.** `phenol_hydroxylation`
  rests on the Dmp/Tom multicomponent monooxygenase, which also hydroxylates
  toluene and 2-hydroxytoluene; `phenylpropanoate_dihydroxylation` and
  `hydroxyphenylpropanoate_hydroxylation` rest on Hca and MhpA, which act on the
  propanoate and the cinnamate alike; `anthranilate_degradation_catechol` varies
  only in NADH versus NADPH. The aromatic proposal reached these boundaries by
  hand and named the broader claim rather than the narrower one. The screen
  agrees with it.

The 62 uncorroborated links are the mirror image and are also benign on
inspection: they are curated reactions whose Rhea master is a sibling of the one
KEGG's EC assignment reaches — the two half-reactions of isopropylmalate
isomerase for `leucine_biosynthesis`, the dihydrolipoamide dehydrogenase masters
for `pyruvate_to_acetyl_coa`. A curator chose the master that states the
chemistry at the route's boundary; KEGG's EC-level mapping reaches a different
one. That is a curation decision the screen cannot see, not a broken link.

**Result: the audit closes with no change.** That is a stronger statement than
it looks, because it is now a reproducible one — the same command re-runs it
against any future database version.

## 5. Discovery

1,369 KO accessions are single-reaction, absent from the curated marker layer,
and take part in a reaction touching a declared anchor. Ranked by the Rhea
degree of the anchor they touch, 138 touch an anchor of degree 20 or less and
449 of degree 50 or less; the remainder mostly touch ammonium, glutamate, AMP or
another hub as a by-product and are not candidates.

The top of the ranking is a useful check on the method, because its first entry
is `K22225`, the siroheme decarboxylase whose heterodimer problem the MetaCyc
pass refused and recorded as a retrigger. The screen rediscovers the standing
deferral without being told about it.

Below it, candidates that name concrete curation work:

| Candidate | Anchor touched | What it would add |
|---|---|---|
| `K07823` `pcaF` 3-oxoadipyl-CoA thiolase | `OXOADIPYL_COA` | An alternative system for a reaction already curated |
| `K27848` 3-oxoadipate:acetyl-CoA acetyltransferase | `OXOADIPATE` | An alternative activation route in the aromatic layer |
| `K01906` `bioW`, `K04118`/`K28556` `pimCD` | `PIMELOYL_COA` | The pimeloyl-CoA supply the biotin GIFT currently assumes |
| `K15783` `doeA` ectoine hydrolase | `ECTOINE` | Ectoine as a *substrate*, mirroring the existing biosynthesis GIFT |
| `K10674` `ectD` ectoine hydroxylase | `ECTOINE` | Hydroxyectoine, a distinct compatible solute |
| `K01452` chitin deacetylase | `CHITIN` | A chitin fate the saccharification route does not cover |
| `K19266` lactaldehyde dehydrogenase | `LACTALDEHYDE`, `LACTATE_L` | Connects fucose and rhamnose catabolism to lactate formation |
| `K12660` `rhmA`, `K18339` `LRA4` | `LACTALDEHYDE`, `PYRUVATE` | An alternative rhamnose route through 2-keto-3-deoxy-L-rhamnonate |
| `K00867`/`K03525`/`K09680` pantothenate kinases | `PANTOTHENATE` | The pantothenate-to-CoA segment the vitamin layer stops short of |
| `K16841` `hpxA` allantoin racemase | `ALLANTOIN` | A step in the purine degradation layer |

None of these is adopted here. Each needs the ordinary treatment: a defensible
boundary, a complete Boolean implementation, and a check that it does not
duplicate an existing atomic GIFT. The list is a queue, not a decision.

## 6. What is kept, and where

`data-raw/reference/` gains four derived tables, in the same spirit as
`cazy-subfamily-ec.tsv`: not compiled into the database, not loaded at runtime,
kept so that a curation decision can be re-checked against the exact input that
informed it.

| File | Rows | Content |
|---|---:|---|
| `ko-reaction-specificity.tsv` | 11,124 | Every EC-bearing KO, its ECs, masters, verdict and reviewed-protein support |
| `curated-marker-audit.tsv` | 785 | Every curated KO marker row with its reaction, fan-out, varying participants and flags |
| `route-specificity.tsv` | 204 | Every curated route and how many of its required reactions are specifically evidenced |
| `discovery-candidates.tsv` | 1,369 | Ranked uncurated single-reaction KOs touching a declared anchor |

The downloaded inputs are cached under `data-raw/reference/.cache` and are not
committed. Input digests at the time of this assessment:

```text
2b449ac148ab155880fd0c751ba5a76b0448f05e42a5079e1877392304a7055a  rhea2ec.tsv
0b62f0cd92991b89e7b6e05707e671e80787527c30192b3d44cf7fc05a5c748f  rhea-directions.tsv
06ff85d8edf224c0d7f21f321272add5868d2e26b99bb11eb004f1fabd148e11  rhea-reactions.txt.gz
0dcfdb4fb8cdc126004f9fee9fd519e605ec09a6ad5ecf495baf0a29063498d7  rhea2uniprot_sprot.tsv
198c5ad91f20707c9bd46180eab14bad0c9aa183d56c234c57192033868a1205  chebiId_name.tsv
ce484307452ed1803034a455cdae39c1bcc07b91034df4cbdb59d5751e9a1ff0  kegg-ko-list.tsv
84b769dd75719e5c696d18735e5221d101ac908fcd55fe3bc6ea6c23bb53cf3d  kegg-ko-enzyme.tsv
```

## 7. Standing limitations

- **One namespace.** CAZy is screened by `ec_fraction` in
  `cazy-subfamily-ec.tsv`, which is a different and weaker measurement;
  Pfam and TIGRFAM markers are not screened at all. An equivalog-level HMM
  namespace would be the natural way to extend this, and is assessed separately.
- **Rhea coverage is the ceiling.** 1,435 KOs carry a complete EC that Rhea does
  not cover, and 2,017 carry only partial ECs. A KO in either group is invisible
  to the screen, which is not evidence that it is broad or narrow.
- **The screen cannot separate an ambiguous ortholog from a promiscuous
  enzyme.** Section 2. Every flag needs a curator.
- **No saturation filter, and it matters.** The screen ranks a candidate by how
  specific the anchor it touches is, which says whether a candidate is
  *markable*. It says nothing about whether the resulting trait would be
  *informative*. The 2026.22.1 release found this the hard way: pantothenate
  kinase ranks highly and the trait is worthless, because cofactor activation is
  complete in essentially every genome and a capability that partitions nothing
  carries only annotation noise. A prevalence column and a saturation flag are
  the next thing to add. See [anchor fates](proposal-anchor-fates.md) §2.
- **KEGG orthology is a moving target.** The KO list is re-issued continuously.
  Re-running the screen after a KEGG update may move accessions between
  verdicts; that is a reason to re-run it before a release, not a reason to
  treat any single run as final.

## 8. Retrigger

Re-run and re-read this assessment when any of the following happens:

- a new marker namespace is admitted, especially one with equivalog-level
  specificity;
- a Rhea release adds masters for chemistry gifter curates;
- a GIFT is added whose claim names a substrate rather than a chemistry;
- the deferral register records a candidate blocked on marker specificity.

```sh
Rscript data-raw/marker_specificity_screen.R
```
