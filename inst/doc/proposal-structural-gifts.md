# Structural GIFTs: curated content, refusals, and open questions

Status: partly implemented. `flagellar_apparatus` and `type_iva_pilus` are
curated; the coupling-ion-specific flagellar traits are **refused** at the
current evidence level and are documented here rather than silently curated.

A **structural GIFT** claims:

> the genome encodes the machinery required to build a defined cellular
> structure or molecular machine, supported by at least one complete curated
> architecture of required structural and assembly functions.

It does not claim expression, assembly in vivo, or any downstream behaviour of
the structure. See [the architecture guide](architecture.md#gift-types) for the
Boolean contract.

## 1. Flagellar apparatus

### The claim

> The genome encodes the structural and assembly machinery of a bacterial
> flagellum: a type III export apparatus, basal body, C ring, hook, filament and
> stator belonging to at least one curated flagellar architecture.

A positive call does **not** mean the organism is motile. Motility additionally
requires expression, correct assembly, an energised membrane, and — for directed
movement — the chemotaxis machinery, which is a regulatory capability and is
deliberately not part of this GIFT.

### Boundary

Included: the parts of the finished structure and the machinery that builds it.

Excluded, with reasons:

| Excluded | Reason |
|---|---|
| FlhD, FlhC, FliA, FlgM (K02402, K02403, K02405, K02398) | Transcriptional regulators of flagellar genes. They govern *when* a flagellum is built, not *whether the genome encodes one*. If curated at all they belong to a regulatory GIFT. |
| FlgD (K02389) | Hook assembly scaffold, removed from the finished structure. |
| FliJ (K02413) | Small, poorly conserved export escort. Requiring it would report absent machinery in genomes that build flagella. |
| FliY (K02424) | KEGG assigns this accession to an L-cystine transport binding protein. It is not specific to the flagellar switch, so it is not evidence for it. |
| MotX, MotY (K21217, K21218) | T-ring proteins of the sodium-type polar motor. See the refusal below. |
| Chemotaxis Che proteins | A regulatory circuit, not part of the structure. |

### Architectures

Two, sharing nine of ten functions:

```text
ARCH_FLAGELLUM_DIDERM     export gate, export ATPase, MS ring, rod,
                          L and P rings, C ring, hook,
                          hook-filament junction, filament, stator
ARCH_FLAGELLUM_MONODERM   the same without the L and P rings
```

They are two architectures rather than one architecture with an optional part,
because a monoderm envelope has no outer membrane for the L ring to sit in: the
bushings are absent by construction, not merely unannotated. A diderm genome
completes both, which is correct — it satisfies both descriptions — and the
report says so through `number_of_complete_architectures`.

### Refused: proton- versus sodium-driven flagellar apparatus

The invariant is that the specificity of a GIFT claim must not exceed the
specificity of the genomic evidence supporting it. Ion coupling fails it.

Evidence, verified against the KEGG REST API on 2026-08-18:

- *Vibrio cholerae* PomA (`vch:VC_0892`) and PomB (`vch:VC_0893`), the
  sodium-driven polar flagellar stator, are assigned to **K02556** and
  **K02557** — the same orthologues as the proton-driven MotA and MotB of
  *Escherichia coli*.
- KEGG has no separate orthologue for PomA/PomB or for the alkaliphilic
  *Bacillus* MotP/MotS sodium stator.

A `proton_driven_flagellar_apparatus` GIFT evidenced by K02556/K02557 would
therefore fire on every *Vibrio* genome, which is sodium-driven. That is not a
conservative error; it is a wrong call.

Two narrower claims were considered and also deferred:

1. **MotX/MotY as sodium evidence.** K21217 and K21218 are specific to the
   T ring of the sodium-type polar motor, so they are not ambiguous in the way
   the stator accessions are. But they evidence a *scaffold that recruits* the
   sodium stator, not an ion channel, and they are absent from the *Bacillus*
   MotPS sodium motor. The defensible claim would be narrower than
   "sodium-driven flagellar apparatus" — something closer to "encodes the T ring
   of the sodium-type polar flagellar motor" — and its usefulness has not been
   established.
2. **Family-level markers.** Pfam does not separate them either: MotA and PomA
   both belong to the MotA/TolQ/ExbB proton channel family.

**What would license the split.** A curated HMM pair, in the `CUSTOM_HMM`
namespace, that separates PomA/PomB and MotP/MotS from MotA/MotB with reported
sensitivity and specificity on a labelled reference set. Nothing in the schema
blocks this: the marker layer is already an open `namespace + accession` pair,
so the split would be a content change, curating a sodium stator system
alongside the current one and adding the two ion-specific GIFTs above the shared
functions. No schema work is required.

Until then `flagellar_apparatus` is deliberately silent about the coupling ion,
and the system description says so where a curator will read it.

## 2. Type IVa pilus

### The claim

> The genome encodes the machinery required to assemble a type IVa pilus:
> prepilin processing, a major pilin, an extension ATPase, the inner membrane
> platform, the PilMNOP alignment subcomplex and the PilQ secretin.

### What the claim deliberately excludes

Twitching motility, natural competence and host adhesion are all *downstream*
of having a pilus, and each needs its own evidence:

| Downstream phenotype | Additional evidence it would need |
|---|---|
| Twitching motility | The retraction ATPase, plus the same expression and energetics caveats as flagellar motility. Retraction is curated as an accessory function of the pilus, so a genome without PilT still completes the structural GIFT. |
| Natural competence | The DNA uptake machinery — ComEA, ComEC, DprA and their partners — none of which is part of the pilus. |
| Adhesion | Adhesin identity and target specificity, which the assembly machinery does not encode. |

This is the structural instance of the marker-specificity invariant: the
machinery is what the markers evidence, so the machinery is what is claimed.

### Scope: type IVa, not "type IV"

The PilM/N/O/P alignment markers are specific to the type IVa system. Type IVb
pili (for example the toxin-coregulated pilus, KEGG M00852) and Tad pili use
different alignment components and are different architectures. Naming the GIFT
`type_iv_pilus` would have claimed a breadth the evidence does not cover, so it
is named `type_iva_pilus`.

### Pilin evidence

`K02650` (PilA) is accepted as `curated` evidence for the major pilin.
`K02655` (PilE) is accepted as `ambiguous`: it is the major pilin in
*Neisseria* but a minor pilin in *Pseudomonas*, so the accession alone does not
establish that the protein is the polymerised subunit. Refusing it would call
*Neisseria*-type systems absent; accepting it silently would equate two roles.
Accepting it at reduced confidence does neither — the confidence ordering
carries the doubt to the call, which reports `ambiguous` for any genome that
depends on it.

## 3. Deferred: spore formation

Sporulation is **not** proposed as a structural GIFT. Building an endospore is
not the assembly of one molecular machine; it is a coordinated developmental
programme with an ordered sequence of compartment-specific sigma factor
regulons, an asymmetric division, engulfment, and a cascade of morphological
stages whose completeness is not well described by "at least one architecture of
jointly required functions".

Forcing it into the structural model would either flatten the programme into a
gene checklist — exactly what discrete completeness exists to avoid — or invent
an architecture nobody could defend.

It is recorded here as a candidate for a future **programmatic** GIFT type,
whose completeness contract would have to state what makes a developmental
programme complete. That type is deliberately **not** added to the schema now:
adding a vocabulary term before any content can be curated against it is how
type vocabularies stop meaning anything.

## 4. Open questions

1. Should a structural GIFT be allowed to declare a *composition* relationship
   with another GIFT, the way metabolic GIFTs compose through anchors? The
   flagellum contains a type III secretion system, and a curated T3SS GIFT would
   overlap it. Anchors cannot express this, and nothing in the current schema
   does. Until a second overlapping structural GIFT exists, duplicating the
   export functions is not yet a problem worth a schema for.
2. `structural_class` currently has three registered values and two are unused.
   The vocabulary should grow with curated content, not ahead of it.
3. A structural GIFT has no `gift_profile` row, because the profile is derived
   from anchors. Whether a structural analogue — surface-exposed, envelope-
   spanning, cytoplasmic — is worth deriving is an open question, and it should
   be derived from curated component properties rather than curated directly.
