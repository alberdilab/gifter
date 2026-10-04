# Curation proposal: antimicrobial detoxification, and CARD as a gifter source

Status: **assessed 2026-08-22; the two proposed GIFTs were curated in database
2026.35.1.** The adoption and retained limits are recorded in
[`proposal-regulatory-defense-expansion.md`](proposal-regulatory-defense-expansion.md).
The original assessment proposed two GIFTs, deferred two candidate families,
and documented five biological refusals. The subsequent curation registered
the `challenge_class` facet. **No new namespace,
no new `gift_type`, no schema change, and no CARD content vendored into the
package.**

The request was whether the Comprehensive Antibiotic Resistance Database (CARD)
is worth mining for GIFTs related to antimicrobial resistance. The short answer
this assessment reaches is that CARD is worth *consulting* and not worth
*ingesting*: its organising axis is the one gifter refuses, the majority of its
content is not expressible in the evidence layer, its licence is incompatible
with an MIT-0 package, and the subset that survives every one of those filters
turns out to be already reachable through KEGG orthology.

That subset is real, though, and it is proposed here.

---

## 1. Decision summary

| Candidate | Type and model | Decision | Decisive reason |
|---|---|---|---|
| `beta_lactam_detoxification` | defense; `chemical_detoxification` | **curate** | Enzymatic conversion of the challenge chemical, Rhea-covered, four Ambler classes as alternative systems, 5010 genomes. §6 |
| `chloramphenicol_detoxification` | defense; `chemical_detoxification` | **curate** | Acetyl-CoA-dependent inactivation, Rhea-covered, two CAT types, 1777 genomes. §7 |
| Aminoglycoside modification | defense; `chemical_detoxification` | **defer** | The chemistry is curatable but no marker resolves "aminoglycoside"; the resolvable level is one drug, and streptomycin alone reaches 480 genomes. §8 |
| `tetX` tetracycline oxidation | defense; `chemical_detoxification` | **defer** | The cleanest destroying chemistry in the roster, at 34 genomes — inside the test's 20–50 band. §8 |
| Erm 23S methylation | — | **refuse** | Target alteration. The mechanism modifies the ribosome, not the drug; excluded by the class definition. §9.1 |
| TetM/TetO ribosome protection | — | **refuse** | Target protection. Nothing is converted. §9.1 |
| Van D-Ala-D-Lac target replacement | — | **refuse** | Target replacement. The marker (`K15739`) and the prevalence both pass; the drug is never converted. §9.2 |
| Tripartite RND efflux | — | **refuse as a defense GIFT** | No chemical conversion; and the marker set cannot name a pump or resolve its substrates. §9.3 |
| Variant- and SNP-based resistance | — | **refuse** | *gyrA*, *rpoB*, 23S. Resistance is a residue, and the evidence layer has no accession for a residue. §9.4 |
| CARD as a runtime namespace | — | **refuse** | §4, §5, §10 |
| `challenge_class` facet | vocabulary | **register** | Reserved by `proposal-aromatic-degradation.md` §10.6; this is its first content. §11.2 |

Net: two defense GIFTs, both `chemical_detoxification`, both single-required-
function, adding one facet and 68 markers already present in KEGG.

---

## 2. What was asked, and what "AMR GIFT" would have to mean

The request names a target — traits "related to AMR" — rather than a capability.
That is the first thing to resolve, because gifter does not curate traits
related to an outcome; it curates capabilities, and the four `gift_type` models
each state what a positive call is allowed to claim.

`proposal-defense-gifts.md` refuses outcome claims twice — "explicitly **not**:
this organism resists phage", and any claim about an infection's outcome is not
a property of a genome sequence — and `proposal-aromatic-degradation.md` §10.6
refuses `metal_resistance` as a `defense_class` on the same grounds, in a
section whose roster already contains the AMR row:

> Antibiotic destruction, target modification, target protection, efflux —
> `K01467` AmpC, `K00561` ErmA/C, `K18220` TetM, `K18138` AcrB — **mixed**

So the question "is CARD worth mining for AMR GIFTs" cannot be answered as
posed. It decomposes into two answerable questions, and this proposal answers
both:

1. Is there a **capability** behind some part of the AMR literature that gifter
   can claim honestly? Yes — the enzymatic destruction of the drug, which is
   already the definition of an existing `defense_class`.
2. Is **CARD** the right source for its markers? No, and §4, §5 and §10 give
   three independent reasons.

---

## 3. The class definition already decides most of the roster

`chemical_detoxification` was defined in `facet_terms.tsv` as:

> A system whose curated function is the enzymatic conversion of a toxic
> chemical challenge into a less harmful chemical species. The class names the
> mechanism, not the outcome: a positive call does not claim that the organism
> tolerates or survives exposure. Efflux, sequestration and repair of the damage
> are excluded by the definition, because none of them converts the challenge
> chemical.

That definition was written for mercury, methylglyoxal and superoxide. Applied
to CARD's own mechanism vocabulary it partitions the field before a single
marker is looked up:

| CARD resistance mechanism | Converts the challenge chemical? | Verdict |
|---|---|---|
| Antibiotic inactivation | **yes** | in scope — §6, §7, §8 |
| Antibiotic target alteration | no — modifies the ribosome or PBP | out — §9.1 |
| Antibiotic target protection | no — binds the target | out — §9.1 |
| Antibiotic target replacement | no — builds a different target | out — §9.2 |
| Antibiotic efflux | no — moves the drug | out — §9.3, and the same cut that keeps *merT*/*merP* accessory to MerA |
| Reduced permeability to antibiotic | no — and it is an absence | out |
| Resistance by absence | no — an absence is not a capability | out |
| Modification to cell morphology | no | out |

One of CARD's eight mechanisms is a `chemical_detoxification` candidate. This is
not a defect in CARD; it is what it means for two resources to be organised on
different axes. CARD partitions by *how the cell survives the drug*, gifter
partitions by *what the encoded machinery does*, and only the inactivation
branch is the same set under both descriptions.

---

## 4. What CARD holds, and what the evidence layer can express

CARD 3.x, read from `card.mcmaster.ca` on 2026-08-22, reports 9051 ontology
terms, 6453 reference sequences, **4463 SNPs** and 6489 AMR detection models
across nine model types: protein homolog, protein variant, protein
overexpression, rRNA gene variant, protein knockout, nonfunctional insertion,
gene cluster meta-model, efflux pump system meta-model, and protein domain
meta-model.

Sort those nine against gifter's evidence layer, which stores one thing —
`namespace` + `accession` attached to a component:

| Model type | Expressible as a gifter marker? |
|---|---|
| Protein homolog | yes, if an orthology group of matching specificity exists |
| Protein domain meta-model | yes in principle, as PFAM/TIGRFAM |
| Protein variant | **no** — the claim is a residue, not a gene |
| rRNA gene variant | **no** — and the gene is not a protein annotation |
| Nonfunctional insertion | **no** — the claim is a disruption |
| Protein knockout | **no** — the claim is an absence |
| Protein overexpression | **no** — the claim is a regulatory state |
| Gene cluster meta-model | **no** — requires co-localisation, which an unordered marker set cannot establish |
| Efflux pump system meta-model | **no**, same reason |

The 4463 SNPs are the sharpest form of this. A *gyrA* S83L substitution is the
entire content of the fluoroquinolone claim, and the gene carrying it is a
housekeeping topoisomerase present in every genome in the database. A marker for
"*gyrA*" would be complete in essentially every bacterium, and would mean
nothing.

This is the same wall the CRISPR array hit in `proposal-defense-gifts.md`: a
feature that is real, decisive for function, and has no `namespace + accession`
identity. There the resolution was to narrow the claim to the protein machinery
and say so in the name. Here there is no narrowed claim left — "encodes a DNA
gyrase" is not a resistance capability by any reading — so the resolution is
refusal (§9.4).

Three of the nine model types clear the evidence layer. Two of those three
(gene cluster and efflux pump meta-models) fail a *second* filter,
co-localisation, which the previous release refused for type III/type VI
secretion — and which `proposal-genomic-context.md` is currently reassessing as
an optional, non-decisive axis (see §9.3):
"system identity depends on several homologous components being co-localised in
one architecture; an unordered marker set cannot establish that."

---

## 5. The test, applied

The test from `proposal-aromatic-degradation.md` §6, unchanged, with its stated
threshold: curate at ≥ 50 complete KEGG genomes, defer between 20 and 50 with a
re-test condition, refuse below 20.

Prevalence is the number of distinct KEGG genomes carrying a KO, out of 11 949
genome entries, from `https://rest.kegg.jp/link/genes/ko:<KO>` intersected
locally on 2026-08-22. For a GIFT whose function has alternative systems, the
number that decides curation is the **union** across those systems, because the
function is complete under any one of them.

| Candidate | Marker set | Union prevalence | Substrate-specific marker? | Verdict |
|---|---|---|---|---|
| β-lactam hydrolysis | 66 KOs, EC 3.5.2.6 | **5010** | yes, at the Ambler-class level | **curate** §6 |
| Chloramphenicol acetylation | `K19271`, `K00638` | **1777** | yes | **curate** §7 |
| Aminoglycoside acetylation | `K00662`, `K19275`–`K19277`, `K03395` | 1308 | no — resolves the position, not the drug | **defer** §8 |
| Aminoglycoside phosphorylation | `K00897`, `K19272`, `K19274`, `K19299`, `K19300`, `K19315`, `K19543` | 741 | no, same reason | **defer** §8 |
| Streptomycin modification | `K00984`, `K10673` | 480 | yes for streptomycin | **defer** §8, with the narrowest re-test |
| Macrolide phosphorylation | `K06979` *mph* | 427 | yes | **defer** §8 |
| Tetracycline 11a-monooxygenation | `K18221` *tetX* | 34 | yes | **defer**, 20–50 band, re-test condition §8 |
| Macrolide esterase (*ereA*) | none | — | **no KO exists** | **refuse** §9.5 |
| Erm 23S methylation | `K00561` | 638 | yes, but wrong mechanism | **refuse** §9.1 |
| TetM/TetO protection | `K18220` | 1040 | yes, but wrong mechanism | **refuse** §9.1 |
| Tripartite RND efflux | `K18138` + `K03585` + (`K12340` \| `K18139`) | 5076 all three | no | **refuse** §9.3 |

Two curate, five defer, four refuse.

---

## 6. `beta_lactam_detoxification` — the accepted GIFT

### The claim

> The genome encodes at least one β-lactamase, and therefore the capability to
> hydrolyse the β-lactam ring, converting a β-lactam antibiotic into a
> substituted β-amino acid that no longer inhibits penicillin-binding proteins.

Explicitly **not**: that the organism is resistant to any β-lactam, that the
enzyme is expressed, that it is exported to the periplasm, that its spectrum
covers penicillins, cephalosporins or carbapenems, or that it confers a clinical
phenotype. Every one of those is either an outcome or a parameter the orthology
groups do not resolve.

The chemistry has a Rhea master, and its generality is the point:

```text
RHEA:20401   a beta-lactam + H2O = a substituted beta-amino acid
```

Rhea records this reaction at the class level, with a generic substrate. The
markers resolve to the class level. The claim is therefore stated at the class
level, and the three agree — which is the condition
`proposal-aromatic-degradation.md` §10.5 exists to enforce.

### Boolean placement

One mechanism, one required function, four alternative systems:

```text
MECH_BETA_LACTAM_HYDROLYSIS
  DF_BETA_LACTAM_HYDROLYSIS        required
    SYS_DF_BLA_CLASS_A   serine, class A     COMP_DF_BLA_CLASS_A
    SYS_DF_BLA_CLASS_B   metallo, class B    COMP_DF_BLA_CLASS_B
    SYS_DF_BLA_CLASS_C   serine, class C     COMP_DF_BLA_CLASS_C
    SYS_DF_BLA_CLASS_D   serine, class D     COMP_DF_BLA_CLASS_D
```

| System | Ambler class | KOs | Genomes |
|---|---|---|---|
| `SYS_DF_BLA_CLASS_A` | serine, class A | 18, led by `K17836` *penP* | 3081 |
| `SYS_DF_BLA_CLASS_B` | metallo, class B | 8, led by `K17837` | 1086 |
| `SYS_DF_BLA_CLASS_C` | serine, class C | 9, led by `K01467` *ampC* | 1708 |
| `SYS_DF_BLA_CLASS_D` | serine, class D | 31, led by `K17838` *oxa* | 1088 |
| **union** | | **66** | **5010** |

### All 66 KOs are admitted, as markers, under four components

This is the decision that answers the CARD question in its most useful form, so
it is argued rather than asserted.

KEGG carries β-lactamase orthology at two granularities. Four groups are defined
by Ambler class (`K17836`, `K17837`, `K01467`, `K17838`), and 62 are defined by
allele family — `blaTEM`, `blaSHV`, `blaCTX-M`, `blaKPC`, `blaNDM`, `blaOXA-48`
and so on. That is exactly the resolution CARD is usually reached for.

Measured against the curation threshold, the allele groups fail and the class
groups pass, decisively:

| Group | Genomes |
|---|---|
| `K17836` *penP*, class A | 2856 |
| all 17 other class A KOs combined | 243 |
| `K01467` *ampC*, class C | 1571 |
| all 8 other class C KOs combined | 143 |
| `K18698` *blaTEM* | 76 |
| `K18768` *blaKPC* | 42 |
| `K18767` *blaCTX-M* | 25 |
| `K18780` *blaNDM* | 22 |

The prevalence lives at the class level. Every named allele group except
`blaTEM` and `blaZ` (76 each) sits at or below the 50-genome line, and the four
carbapenemase families that motivate most AMR surveillance — KPC, NDM, VIM, IMP
— are at 42, 22, 6 and 10.

The resolution is not to choose one granularity over the other. Marker logic is
OR, so the allele groups are admitted as **additional markers on the class
component they belong to**. `COMP_DF_BLA_CLASS_A` accepts `K17836` *or*
`blaTEM` *or* `blaKPC` *or* the other 15; a genome annotated only `blaNDM`
completes through `COMP_DF_BLA_CLASS_B`. Sensitivity is the union, 5010, and no
claim is ever made at a specificity the marker cannot carry.

**This is the whole of what CARD-grade allele resolution buys, and gifter can
hold it without CARD.** The allele identity does useful work as *evidence* and
none as a *claim*, which is the same shape as every marker-versus-trait decision
in the curated database.

### Design decisions to review

1. **The GIFT has no incomplete state.** One required function with four
   alternative single-component systems means every call is complete or absent;
   `best_implementation` and `missing_requirements` carry no information. This
   is a genuine departure from the layered completeness that motivates gifter,
   and it is the strongest argument against curating this GIFT at all. It is
   accepted for three reasons: `mercury_detoxification` already has a single
   required function and was curated on that basis; the curation content here is
   the *partition* of 66 orthology groups into four defensible systems plus the
   refusal of everything in §9, which is not recoverable from a raw annotation
   table; and the GIFT becomes available to the community layer, reference
   frames and provider counts, which a loose KO list is not.
2. **Class B is chemically distinct and is still one system, not one
   mechanism.** Metallo-β-lactamases hydrolyse through a Zn(2+)-activated
   hydroxide rather than a serine acyl-enzyme. The substrate and product are
   identical and Rhea assigns both to `RHEA:20401`, so they are alternative
   implementations of one function, which is what a system is. Making them
   separate mechanisms would imply the GIFT has two complete implementations to
   distinguish, and nothing downstream would use the distinction.
3. **The metallo-β-lactamase fold is not the metallo-β-lactamase enzyme, and
   the marker must be the enzyme.** The MBL fold is carried by glyoxalase II —
   already curated here as `COMP_DF_MG_GLOB` (`K01069`) under
   `methylglyoxal_detoxification` — and by many unrelated hydrolases. `K17837`
   is admissible because KEGG defines it by EC 3.5.2.6 rather than by fold. Any
   future PFAM or InterPro marker for this component must be checked against
   the fold-versus-enzyme distinction before admission; this is the §9.1 failure
   mode of the aromatic proposal in a new place.
4. **Taxonomy confirms the claim is about machinery, not clinical resistance.**
   The genera carrying a β-lactamase are led by *Streptomyces* (217),
   *Pseudomonas* (212), *Streptococcus* (180), *Bacillus* (147) and
   *Burkholderia* (96), with *Escherichia* (72), *Staphylococcus* (69),
   *Acinetobacter* (61) and *Klebsiella* (54) further down. A β-lactamase is a
   widespread environmental enzyme. Reading a positive call as a clinical
   resistance phenotype would be wrong in the majority of genomes that carry
   one, which is precisely why the claim is worded as it is.

---

## 7. `chloramphenicol_detoxification`

### The claim

> The genome encodes a chloramphenicol O-acetyltransferase, and therefore the
> capability to acetylate chloramphenicol using acetyl-CoA, converting it to a
> derivative that no longer binds the 50S ribosomal subunit.

```text
RHEA:18421   chloramphenicol + acetyl-CoA = chloramphenicol 3-acetate + CoA
```

One mechanism, one required function, two alternative systems:

| System | KO | Genomes |
|---|---|---|
| `SYS_DF_CAT_TYPE_A` | `K19271` *catA* | 1081 |
| `SYS_DF_CAT_TYPE_B` | `K00638` *catB* | 866 |
| **union** | | **1777** |

Both KEGG groups are defined by EC 2.3.1.28, so the substrate is part of the
group definition. The two CAT types are structurally unrelated — type A is the
classic trimeric CAT, type B a hexapeptide acyltransferase — which is the
textbook case for two systems under one function.

**To review:** CatB enzymes belong to a hexapeptide acyltransferase family with
known promiscuity toward other substrates. The EC assignment is the reason
`K00638` is admitted, and if a later KEGG revision widens that group beyond
chloramphenicol the marker must be re-graded, not the trait renamed. Recorded as
an open question in §12.

---

## 8. The deferrals, with re-test conditions

**Aminoglycoside modification** is the interesting refusal, because the
chemistry passes and the *name* fails. Three mechanisms exist and all are proper
detoxification — N-acetylation (AAC, 1308 genomes), O-phosphorylation (APH, 741,
`RHEA:24256`), and O-adenylylation (ANT). A GIFT called
`aminoglycoside_detoxification` would be complete in a genome carrying only
`K00984` *aadA*, which adenylylates streptomycin and spectinomycin and does
nothing to gentamicin, kanamycin, tobramycin or amikacin.

That is the §9.1 failure mode exactly: no marker resolves the substrate named in
the trait. The test's own remedy applies — "refuse the trait, or rename it to
the substrate range the marker actually resolves" — and the resolvable range is
one drug or a small group.

Deferred rather than refused, because the rename is available and the numbers
support it:

| Narrowed candidate | Markers | Genomes | Re-test condition |
|---|---|---|---|
| Streptomycin modification | `K00984` *aadA* + `K10673` *strA*, both acting at the 3'' position | **480** | Confirm both KEGG groups are streptomycin-specific and that *aadA*'s spectinomycin activity does not require a two-drug claim; then curate as one GIFT with two systems |
| Macrolide phosphorylation | `K06979` *mph* | 427 | Confirm the group's macrolide range is narrower than the trait name would imply |
| Kanamycin/neomycin phosphorylation | `K00897`, `K19272`, `K19274`, `K19299`, `K19300` | 741 union | Requires deciding whether APH(3') subtypes share a claimable substrate range |

**`tetX` tetracycline 11a-monooxygenation** (`K18221`, EC 1.14.13.231) is
chemically the cleanest antibiotic-destroying enzyme in the whole roster — an
FAD-dependent oxidation that irreversibly destroys the tetracycline. It is
deferred on prevalence alone, at 34 genomes, inside the test's 20–50 band. The
re-test condition is a KEGG genome set in which `K18221` clears 50, or a
host-associated dataset in which it is observed; the chemistry and the marker
specificity are not in question.

---

## 9. The refusals, with evidence

### 9.1 Target alteration and target protection convert nothing

`K00561` *ermC*/*ermA* (638 genomes) dimethylates A2058 of 23S rRNA, and
`K18220` *tetM*/*tetO* (1040 genomes) is a ribosome protection GTPase that
dislodges tetracycline from the ribosome. Both are prevalent, both have
substrate-specific orthology groups, and both would pass the first and third
clauses of the test.

They are refused on the class definition, which excludes them by construction:
the challenge chemical is unchanged. Erm modifies the ribosome; TetM binds it.
This is the same cut that excludes efflux and repair, and it is the reason the
class was named for the mechanism in the first place.

Neither is homeless. Erm methylation is a real capability and could be curated
later under a different `defense_class` naming what it does — modification of
the cell's own target — provided that class is populated by more than one
member before it is registered, per the §11.2 rule that a facet vocabulary is
registered when the first content needing it is curated. It is not proposed
here.

### 9.2 Vancomycin target replacement: everything passes except the mechanism

This is the most instructive refusal in the set, because it fails on one clause
only.

Target replacement rebuilds the peptidoglycan terminus as D-Ala-D-Lac so that
vancomycin no longer binds. The defining enzyme has a good marker — `K15739`
*vanA*/*vanB*/*vanD*, D-alanine---(R)-lactate ligase, EC 6.1.2.1, in 107 genomes
— which clears the specificity clause (the group is defined by the ligase
reaction that makes the mechanism what it is) and the prevalence clause (107 is
above the 50-genome line). The accessory *van* proteins `K18346` *vanW*,
`K18353` *vanJ* and `K18354` *vanK* exist as separate groups, and the *vraSR*
two-component system (`K07681`, `K07694`) is available as the regulatory arm.
A curator could build this GIFT.

It is refused because the drug is untouched. Vancomycin is neither converted nor
removed; the cell rebuilds its own target around it. That is not
`chemical_detoxification` under a definition that turns on "enzymatic conversion
of a toxic chemical challenge", and there is no other defense class it belongs
to.

Recording it here matters more than refusing it. `K15739` is a well-marked,
well-attested capability with a natural home in some future class — it is the
strongest single candidate for the target-alteration class discussed in §9.1,
and if that class is ever populated, vancomycin target replacement and Erm 23S
methylation are its first two members.

### 9.3 Tripartite RND efflux is the most tempting candidate and still fails

This is the one AMR-adjacent capability with the right *shape* for gifter's
Boolean model: a genuine heterocomplex of three jointly required parts, each
with a distinct orthology group, which is the argument that made type I
restriction-modification the cleanest first defense example.

The numbers are strong:

| Part | KO | Genomes |
|---|---|---|
| Inner-membrane RND transporter | `K18138` *acrB*/*mexB*/*adeJ* | 6066 |
| Periplasmic adaptor (membrane fusion protein) | `K03585` *acrA*/*mexA*/*adeI* | 5787 |
| Outer-membrane channel | `K12340` *tolC* or `K18139` *oprM* | 5466 |
| **all three present** | | **5076** |

It is refused three times over:

1. **No chemical conversion.** The class definition excludes efflux explicitly,
   and §10.6 of the aromatic proposal already used efflux as the worked example
   of what `chemical_detoxification` must not admit. Curating it here would
   reopen a boundary that was closed with reasons.
2. **The markers do not resolve the substrate.** `K18138` is one orthology group
   covering AcrB, MexB, AdeJ, SmeE, MtrD and CmeB. These pumps export bile
   salts, detergents, dyes, host antimicrobial peptides and, incidentally, many
   drugs. No claim mentioning an antibiotic survives contact with that group.
3. **Co-occurrence is not a complex.** 5076 genomes carry all three parts
   somewhere, but TolC serves many pumps and most genomes encode several RND
   systems; nothing in an unordered marker set says which adaptor pairs with
   which transporter. This is the co-localisation refusal that
   `proposal-next-gift-release.md` applied to type III/type VI secretion.

`inst/doc/proposal-genomic-context.md` is assessing exactly the input that would
speak to the third point, and it should be read before this section is taken as
settled. Its §4.1 recommends contig identity and gene distance as optional
evidence precisely at the AND layer — jointly required components of one system,
which is what these three parts would be — so a future implementation could
report that a genome's *acrA*, *acrB* and *tolC* are neighbours rather than
scattered.

That would weaken the third reason and neither of the first two. Its §7 hard
rules keep context non-decisive, so the call would still be made on
co-occurrence alone; and the class definition (reason 1) and the marker's
substrate range (reason 2) are untouched by knowing where the genes sit. The
refusal therefore stands on reasons that do not depend on the outcome of that
assessment, which is the condition for recording it as a refusal rather than a
deferral.

If multidrug efflux is wanted later it is a **transport** capability named for
the machinery — a tripartite RND efflux apparatus — and not a defense GIFT and
not an antibiotic claim. Recorded as an open question, not proposed.

### 9.4 Variant-based resistance has no accession

Fluoroquinolone resistance through *gyrA*/*parC* substitutions, rifampicin
resistance through *rpoB*, macrolide resistance through 23S A2058 mutations, and
the other 4463 SNPs in CARD are refused as a body. The capability is a residue;
the gene is universal; a marker for the gene would be complete everywhere and
mean nothing. §4 gives the full argument.

This refusal is stable rather than provisional. It does not become curatable
when CARD grows or when KEGG adds groups — it becomes curatable only if the
evidence layer gains a way to express a sequence variant, which is a schema
change with no other motivating content and is not proposed.

### 9.5 Macrolide esterase: EC reassignment, no marker

*ereA*/*ereB* erythromycin esterases hydrolyse the macrolactone ring — clean
detoxification chemistry. EC 3.1.1.101 now resolves in KEGG to `K21104`, which
is **poly(ethylene terephthalate) hydrolase**, present in 1 genome. The EC
number was reassigned and the erythromycin esterase has no usable orthology
group. Refused for want of a marker, with a note to re-check on any KEGG
revision.

---

## 10. The licence finding: CARD content cannot ship in this package

This is independent of every biological argument above and would be decisive on
its own.

gifter is licensed **MIT No Attribution** (`LICENSE`), which grants downstream
users the right to use, sell and sublicense without condition.

CARD's terms, from `card.mcmaster.ca/about` on 2026-08-22, permit free
reproduction of Materials by academic, government and non-profit users, and
state that "use or reproduction of Materials on the site, in whole or in part,
by any commercial organization … is prohibited, except with written permission
of McMaster University", available under a written licence and user fee.

Vendoring CARD sequences, models or curated content into `inst/extdata/` or
`data-raw/reference/` would place non-commercial content inside a package whose
licence promises commercial use. That is a licence conflict, not a formality,
and it is a different situation from the dbCAN files already in
`data-raw/reference/`.

The one exception is the **Antibiotic Resistance Ontology itself, released under
CC-BY 4.0**. ARO term identifiers may be cited — in a `notes` column, in a
proposal, or as a `gift_xref` — provided McMaster University is credited. That
is enough for every use this assessment found a need for, because the ontology
is precisely the part that is useful for *deciding* and the sequences are the
part that would have been useful for *annotating*, and gifter does not annotate.

**Recommendation: consult CARD through its web interface and the CC-BY ontology;
add no CARD file to this repository.**

---

## 11. Facet and vocabulary budget

### 11.1 No new `defense_class`

Both proposed GIFTs are `chemical_detoxification` under the existing definition.
The class was designed to be scoped by mechanism shape rather than by the
periodic table, and antimicrobials are the first non-metal, non-endogenous
challenge to enter it — which is a test of that design and one it passes without
amendment.

### 11.2 `challenge_class` is registered here

`proposal-aromatic-degradation.md` §10.6 recorded that the "against what" axis,
if wanted, is a separate multi-valued facet, and named its expected values:
`metal`, `oxidative`, `nitrosative`, `electrophile`, `antimicrobial`. It was
deliberately not registered at the time, on the rule that a facet vocabulary is
registered when the first content needing it is curated.

This proposal is that content. Two GIFTs enter the class whose challenge is
neither a metal nor an endogenous reactive species, and without the facet the
only way to find them is by name.

Proposed `facet_terms.tsv` additions:

| facet | value | applies_to | definition |
|---|---|---|---|
| `challenge_class` | `antimicrobial` | gift | A chemical challenge that is an antibiotic or other antimicrobial compound produced by another organism or administered externally. |
| `challenge_class` | `metal` | gift | A chemical challenge that is a metal or metalloid species. |
| `challenge_class` | `oxidative` | gift | A chemical challenge that is a reactive oxygen species. |
| `challenge_class` | `electrophile` | gift | A chemical challenge that is a reactive electrophile, typically a metabolic by-product. |

And the retrofit of existing content, which is what makes the facet worth
having:

| gift_id | challenge_class |
|---|---|
| `beta_lactam_detoxification` | `antimicrobial` |
| `chloramphenicol_detoxification` | `antimicrobial` |
| `mercury_detoxification` | `metal` |
| `superoxide_detoxification` | `oxidative` |
| `methylglyoxal_detoxification` | `electrophile` |

`nitrosative` is **not** registered: no curated content needs it yet, and
registering it now would repeat the mistake §10.6 avoided.

### 11.3 No anchors

Defense GIFTs declare no anchors, so neither GIFT touches the anchor budget or
the composition graph. Nothing in this proposal can create a trait edge.

---

## 12. Open questions for the reviewer

1. **Is a GIFT with no incomplete state worth curating?** §6 argues yes on the
   `mercury_detoxification` precedent and on the value of the marker partition
   and the refusals. A reviewer who disagrees should refuse both GIFTs, and the
   §9 refusals still stand as the result.
2. **Should `K00638` *catB* be admitted given hexapeptide acyltransferase
   promiscuity?** Admitted here on the EC assignment; re-grade if KEGG widens
   the group.
3. **Should the 62 allele-level β-lactamase KOs be admitted as markers, or only
   the four class-level groups?** Admitted here, because marker logic is OR and
   they add 345 genomes of sensitivity (4665 to 5010) at no cost to claim
   specificity. The counter-argument is maintenance: 66 markers on four
   components is the largest marker set on any single defense function in the
   database.
4. **Does a future multidrug efflux GIFT belong to `transport`?** §9.3 says yes
   and does not propose it. It would be the first transport GIFT with no
   substrate claim at all, which is a boundary worth deciding before it is
   built.
5. **Should Erm-style target alteration get its own `defense_class` later?** Not
   until it has more than one member.

---

## 13. What this layer would deliberately not claim

- That any organism is resistant to any antibiotic. Every GIFT here claims
  encoded machinery.
- That the enzyme is expressed, correctly localised to the periplasm, or active
  under any condition.
- The spectrum of the enzyme. A class A β-lactamase call does not distinguish a
  narrow-spectrum penicillinase from an extended-spectrum enzyme or a
  carbapenemase, because the group that carries the prevalence does not
  distinguish them.
- That a genome lacking these GIFTs is susceptible. Efflux, target alteration,
  target protection, permeability and variant-based mechanisms are all refused
  above, so absence of a call is not absence of resistance — and a derived
  phenotypic layer, per invariant 18, is where such a statement would have to
  live if it were ever made.

---

## 14. If accepted: curation order and effort

1. Register the four `challenge_class` values in `facet_terms.tsv`; add the five
   `gift_facets.tsv` rows including the three retrofits.
2. Add `beta_lactam_detoxification` to `gifts.tsv`; one row in
   `gift_mechanisms.tsv`, one in `mechanism_functions.tsv`, four in
   `defense_systems.tsv`, four in `defense_components.tsv`, 66 in
   `defense_component_markers.tsv` with `evidence_type = orthology`,
   `confidence = curated`, `source = KEGG orthology, verified against KEGG REST
   2026-08-22`, and a `notes` value on each class component recording the
   fold-versus-enzyme check from §6.3.
3. Add `chloramphenicol_detoxification` the same way: two systems, two
   components, two markers.
4. Record both in `database_changes.tsv` and `change_gifts.tsv`, with the §9
   refusals summarised in the changelog entry, per the rule that a refusal with
   its evidence is a result.
5. Extend `tests/testthat/test-regulatory-defense.R` with the
   alternative-systems case: a genome carrying only `K18780` *blaNDM* completes
   `beta_lactam_detoxification` through `COMP_DF_BLA_CLASS_B`, and a genome
   carrying only `K00561` *ermC* completes nothing.

No R code changes. No schema changes. The mixed-type evaluation path, the
machinery model and the community layer all handle these GIFTs as curated
content.
