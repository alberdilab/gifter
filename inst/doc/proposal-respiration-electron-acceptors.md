# Proposal: respiration, and whether the electron-acceptor boundary should move

Status: **assessment only. The standing refusal stands. Nothing was changed in
the database.** An implementation was attempted during this assessment and
withdrawn: the test suite rejected it, correctly, and this document exists
because that rejection is the answer to a question the refusal itself invited.

**Decision timestamp:** 2026-08-22T18:05Z

**Reopens:** the electron-acceptor boundary stated once in
[nitrogen compound catabolism](proposal-nitrogen-compound-catabolism.md) §8,
and the `FUMARATE` anchor note that preceded it.

---

## 1. What is already decided

> **A capability whose completion requires an external terminal electron
> acceptor is out of scope. Curate the part of the chemistry that ends before
> the acceptor, and name the trait for what that part does.**

That rule refused `nitrate_respiration`, `denitrification`, `dnra` and
`taurine → hydrogen sulfide` in one stroke, and the same document said what
reopening it would take:

> Reversing this is an architectural decision with its own proposal, its own
> completeness contract, and probably its own `gift_type`.

It also predicted precisely how a reversal would be attempted, and guarded
against it with a test:

```r
test_that("respiratory nitrogen and sulfur markers fire nothing", {
  # The electron-acceptor scope. These accessions are specific, abundant and
  # easy to curate, which is exactly why the refusal has to be tested: nothing
  # in the evidence layer would otherwise stop them being added.
```

This assessment began by curating four respiratory GIFTs — nitrate to nitrite,
nitrite to ammonium, trimethylamine N-oxide to trimethylamine, and dioxygen to
water — as ordinary metabolic traits with anchors and routes. The sources
validated, the database compiled, and `test-nitrogen.R` failed exactly where it
was written to fail. The content was reverted. That is the guard working as
designed, and it is also the strongest argument that the question is worth
answering deliberately rather than incrementally.

## 2. What the refusal costs

The refusal is not free, and the cost falls hardest on the host-associated
ecology gifter is aimed at. Counts below are distinct KEGG organisms carrying
the accession, retrieved 2026-08-22; they are not the same denominator as the
genome counts in the nitrogen proposal and are not comparable to them.

| Machinery | Accessions | Organisms |
|---|---|---:|
| Cytochrome bd quinol oxidase | `K00425` `K00426` | 7,257 / 7,191 |
| aa3-type cytochrome c oxidase | `K02274` `K02275` `K02276` | 6,024 / 5,896 / 5,764 |
| cbb3-type cytochrome c oxidase | `K00404` `K00405` `K00406` | 2,749 / 2,753 / 3,049 |
| Cytochrome bo3 quinol oxidase | `K02297`–`K02300` | 2,575–2,702 |
| Membrane-bound nitrate reductase NarGHI | `K00370` `K00371` `K00374` | 2,550 / 2,594 / 2,516 |
| Periplasmic nitrate reductase NapAB | `K02567` `K02568` | 1,453 / 1,349 |
| Cytochrome c nitrite reductase NrfA | `K03385` | 1,055 |
| aa3-600 menaquinol oxidase QoxABC | `K02826`–`K02828` | 600–692 |
| TMAO reductase TorAC / TorZY | `K07811` `K03532` `K07812` `K07821` | 408 / 529 / 569 / 234 |

Two consequences, neither hypothetical:

- **Oxygen tolerance is invisible.** Whether a genome encodes a terminal oxidase
  is the single most structuring functional axis in a gut or rumen community,
  and gifter cannot say. A strict anaerobe and a facultative anaerobe are
  indistinguishable in the catalogue.
- **The nitrogen layer under-describes the genomes that matter.** The nitrogen
  proposal said so itself: a complete denitrifier scores negative on everything
  in that layer.

Nothing here overrides the refusal. A cost is not an argument; it is the reason
to check whether the argument is still the right one.

## 3. The two objections, examined separately

The refusal rests on two independent reasons. They are not equally strong.

### 3.1 The acceptor clause

Stated as written, the clause is about the *reaction*: completion requires an
external acceptor, so the chemistry cannot be bounded. But the database already
curates acceptor-coupled chemistry:

- `succinate_fumarate_interconversion` uses `RHEA:40523`, *a quinone + succinate
  = fumarate + a quinol*. A quinone is in the equation, and the GIFT is curated.
- `taurine_desulfonation_aerobic` consumes dioxygen as a co-substrate. O2 is in
  the chemistry, and the GIFT is curated.

What those two do not do is **name the trait for the acceptor**. The quinone is
internal chemistry, and the `FUMARATE` anchor states the consequence explicitly:
the anchor supports no fumarate respiration claim. So the operative rule is not
"no acceptor in the equation" — it is:

> A trait may not be named for, or bounded by, a molecule whose role in the
> chemistry is to receive electrons, because the resulting claim would be about
> energy conservation, which no completeness model in gifter bounds.

That is a claim-level rule, not an evidence-level one, and it is exactly the
kind of rule a new completeness contract can address. Section 4 does.

### 3.2 Marker direction

`K00370` is named by KEGG **`narG, narZ, nxrA; nitrate reductase / nitrite
oxidoreductase`**. One accession, two opposite reactions, and in nitrite-
oxidising bacteria the reverse is the physiological one. A marker that cannot
say which direction the enzyme runs cannot license a directed catabolic claim.

This objection is correct and independent, and
[the specificity screen](proposal-marker-specificity-screen.md) reaches it from
the other side: `K00370` and `K00371` carry two ECs, `1.7.5.1` and `1.7.99.-`,
and the screen classifies them `multi_reaction_multi_ec`.

But it is **local**. It applies to NarGHI. It does not apply to NapAB, NrfA,
TorAC, TorZY, CydAB, CyoABCD, QoxABC, CoxABC or CcoNOP, none of which carries a
reverse-direction ortholog. A general refusal cannot rest on it; only the Nar
system can.

Note also that a machinery model would not need to resolve it the same way. A
claim of the form "encodes a complete NarGHI-type nitrate reductase complex" is
true of a nitrite oxidiser, because the complex is the same complex. It is the
*directed conversion* claim that the marker cannot support, and a directed
conversion is what the metabolic model produces.

## 4. Three designs

### Design A — keep the refusal

No change. The costs in §2 stand, and gifter continues to say nothing about the
axis that organises anaerobic communities. Defensible, and the only design that
needs no new contract.

### Design B — metabolic GIFTs with acceptor boundaries

Acceptor as input anchor, reduced product as output: `NITRATE` → `NITRITE`,
`NITRITE` → `AMMONIUM`, `TMAO` → `TRIMETHYLAMINE`, `OXYGEN` → `WATER`. This is
what was built and reverted. It works mechanically — sources validate, routes
resolve, the Boolean layers behave — but it is the wrong shape, for three
reasons that only became clear by building it:

1. **It requires a sink anchor.** Nothing acquires water as a resource, so
   `WATER` would be declared as an output and never as an input, enforced by a
   test. That is a rule about an anchor rather than a property of one, which is
   a smell.
2. **It states a conversion, and the conversion is not the capability.** "This
   genome converts dioxygen to water" is chemically true and biologically
   beside the point. What a reader wants is "this genome encodes a complete
   terminal oxidase".
3. **It re-imports the direction problem.** §3.2: a directed catabolic claim is
   exactly what NarGHI evidence cannot carry.

### Design C — a `respiratory` GIFT type, with a machinery model

**Recommended.** Respiration is machinery, not a boundary-to-boundary
conversion, and gifter already has three machinery models that fit the shape:

```text
respiratory GIFT = ANY complete respiratory system
respiratory system = ALL required components
component        = ANY accepted genomic marker
```

Under invariant 17 a non-metabolic type declares no anchors, no routes and no
`mode`, which removes the sink anchor, removes the spurious composition edges,
and removes the directed-conversion claim in one move. The claim becomes what
the evidence actually supports:

> A positive call means the genome encodes at least one complete curated
> terminal reductase or oxidase for the named acceptor. It does not mean the
> acceptor is present, that the organism respires it, that a proton motive
> force is generated, that any particular donor is oxidised, that the organism
> is an aerobe or an anaerobe, or that the enzyme is high- or low-affinity.

The class facet the type needs, by analogy with `structural_class` and
`defense_class`, is `acceptor_class`: `dioxygen`, `nitrogen_oxide`,
`amine_oxide`, `sulfur_oxide`, `organic`.

### What Design C would contain

Curated during this assessment and available as an implementation sketch; every
Rhea master, orthologue and prevalence figure below was verified.

| GIFT | Systems, jointly required components | Reaction identity |
|---|---|---|
| `dioxygen_respiration` | bd `K00425`+`K00426`; bo3 `K02297`–`K02300`; aa3-600 `K02826`–`K02828`; aa3 `K02274`+`K02275`+`K02276`; cbb3 `K00404`+`K00405`+`K00406` | `RHEA:55376` quinol oxidase, `RHEA:11436` cytochrome c oxidase |
| `nitrate_respiration` | Nap `K02567`+`K02568`; Nar `K00370`+`K00371`+`K00374` **only if §3.2 is answered** | `RHEA:12909`, `RHEA:56144` |
| `nitrite_ammonification` | Nrf `K03385` | `RHEA:13089`, used in reverse |
| `tmao_respiration` | TorAC `K07811`+`K03532`; TorZY `K07812`+`K07821` | `RHEA:29271` |

Two notes on that table. The reaction column is provenance, not structure: a
machinery model has no route layer, so the Rhea identity would live in the
system's description rather than in `reactions.tsv`. And `dioxygen_respiration`
is deliberately one GIFT with five systems rather than five GIFTs, because what
separates the families is the electron donor and the affinity, and gifter can
defend neither as a claim.

`tmao_respiration` is the one with a composition story gifter would otherwise
lose: `TRIMETHYLAMINE` is already an output anchor of
`carnitine_degradation_trimethylamine`, so a community carrying both is running
a loop through the host — microbial TMA, host FMO3 oxidation, microbial TMAO
reduction. Under Design C that loop is not represented, because a respiratory
GIFT declares no anchors. That is a real loss and it should be stated rather
than argued away.

## 5. What must be settled before implementing anything

1. **The completeness contract**, written the way the other three types have
   one, plus its validation rules and a fixture-backed example. Invariant 19.
2. **The Nar direction question.** Either Nar is admitted with its ambiguity
   recorded, or it is refused and `nitrate_respiration` rests on Nap alone,
   which under-calls badly. NCBIfam may separate `narG` from `nxrA`; that check
   is one query and has not been run.
3. **Quantitative traits.** A respiratory GIFT would need a named reference
   universe, and a decision about whether it joins existing universes or stands
   apart. `bounded` is a strong claim and this type would not be complete.
4. **Community edges.** Invariant 22 crosses organisms only through an
   `extracellular` anchor. A respiratory GIFT has none, so it creates no edges —
   which is correct, and worth stating explicitly so nobody later infers oxygen
   competition from it.
5. **Whether the amended acceptor clause is the right rule.** §3.1 proposes
   replacing "no external acceptor" with "no trait named for the molecule that
   receives the electrons, and no claim about energy conservation". A machinery
   model satisfies the second version. Someone has to agree it is the version
   that was meant.

## 6. Recommendation

Adopt **Design C**, as a dedicated architectural release, or keep **Design A**
explicitly. Do not adopt Design B.

If Design C is adopted, `dioxygen_respiration` alone justifies it: it is the
most prevalent machinery in the table, it is the axis every host-associated
analysis wants, and it is the one candidate whose evidence carries no direction
ambiguity at all.

If it is not adopted, the refusal should be restated in
[the deferral register](deferral-register.md) — which this assessment has now
done — so that the next pass finds it before building, rather than after.
