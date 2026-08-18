# Defense GIFTs: curated content, refusals, and open questions

Status: **partly implemented**. `type_i_restriction_modification` and
`type_i_e_crispr_cas_machinery` are curated. The CRISPR array limitation below
is unchanged: it is why the second claim is about encoded machinery rather than
interference. Boolean semantics are fixed by synthetic fixtures and by the
curated content in `tests/testthat/test-regulatory-defense.R`.

A **defense GIFT** claims:

> the genome encodes the capability to execute a defined cellular defense
> mechanism against a defined biological or chemical challenge, through at least
> one complete curated mechanism.

```text
DEFENSE GIFT
  |
  +-- OR --> DEFENSE MECHANISM
                       |
                       +-- AND --> DEFENSE FUNCTION
                                        |
                                        +-- OR --> SYSTEM
                                                       |
                                                       +-- AND --> COMPONENT
                                                                      |
                                                                      +-- OR --> EVIDENCE
```

As everywhere else in giftr, completeness is discrete. "Seven of the nine
expected *cas* genes" is not a defense call.

## Curated: type I restriction-modification

### The claim

> The genome encodes a complete type I restriction-modification mechanism:
> sequence recognition, restriction of unmethylated DNA, and methylation of the
> host's own sites.

Explicitly **not**: "this organism resists phage". Restriction-modification is
one of many defense layers, phages carry anti-restriction counter-measures, and
the outcome of an infection is not a property of a genome sequence.

### Why this is the right first defense example

It is the cleanest multisubunit requirement available. The type I enzyme is a
genuine heterocomplex — HsdR restriction, HsdM methylation, HsdS specificity —
and the three subunits have distinct KEGG orthologues (`K01153`, `K03427`,
`K01154`). It therefore tests component AND logic on real biology rather than a
fixture.

### The decomposition as curated

Three functions, all required:

```text
DF_TYPE_I_RM_SPECIFICITY     HsdS (K01154), which directs the complex
DF_TYPE_I_RM_MODIFICATION    HsdM (K03427), which protects host sites
DF_TYPE_I_RM_RESTRICTION     HsdR (K01153), which translocates and cleaves
```

### The three questions, answered

- **Is a genome encoding only HsdM and HsdS a defense capability?** No. It is a
  methylation capability, biologically real and common as an orphan
  methyltransferase, but it defends against nothing. HsdR is required and such a
  genome is correctly called incomplete, missing
  `DF_TYPE_I_RM_RESTRICTION`. A methylation-only claim, if wanted, is a
  different GIFT with a different name.
- **Do the accessions distinguish type I from types II, III and IV?** Yes. The
  KEGG orthology groups are defined as the R, M and S subunits *of a type I
  restriction enzyme*, so the type is part of the group definition rather than
  an inference from it. *E. coli* K-12 carries exactly one of each — the EcoKI
  system.
- **Should the target sequence ever be claimed?** No, and it is not. HsdS
  specificity comes from variable target recognition domains that the orthology
  group does not resolve. This is the same refusal shape as flagellar coupling
  ion: the machinery is claimed, the parameter it is set to is not.

### Recognition and modification are separate functions

HsdM and HsdS together form a functional methyltransferase that exists without
HsdR, which is an argument for putting them in one system. They are kept apart
because the two functions fail independently and the report is more useful when
it says which one is missing. Nothing about the call changes; the diagnostics do.

## Curated, narrowed: type I-E CRISPR-Cas machinery

This candidate stresses the evidence model, and the honest answer is that it
partly breaks it. It was curated under option 1 below.

### The problem

A CRISPR-Cas system is not only proteins. The Cascade complex (`cse1`/`casA`,
`cse2`/`casB`, `cas7`/`casC`, `cas5`, `cas6e`), the Cas3 nuclease-helicase and
the adaptation module (`cas1`, `cas2`) are all proteins with orthologues. But
the system's function depends on a **CRISPR array**: the repeat-spacer locus
that supplies the guide RNAs. A genome with a complete *cas* operon and no array
has no guides and interferes with nothing.

An array is not a protein annotation. It is a genomic feature detected by
structure — direct repeats at a characteristic spacing — and it has no
`namespace + accession` identity. The current evidence layer cannot express it.

### The three honest options

1. **Narrow the claim to what the evidence supports.** Curate
   `type_i_e_crispr_cas_machinery`: "the genome encodes the Cascade,
   interference and adaptation proteins of a type I-E CRISPR-Cas system". This
   is true and checkable from protein markers alone, and it is *not* a claim
   that the system can interfere with anything.
2. **Extend the evidence model to genomic features.** Add a feature-evidence
   layer alongside markers, so a component can be supported by "a CRISPR array
   was detected in this genome". This is a real architectural change: it means
   the evaluation input is no longer only an annotation table, and every
   accessor, trace and confidence rule has to account for a second evidence
   kind.
3. **Refuse the trait** and record why.

### What was done

**Option 1.** The curated claim is:

> The genome encodes the protein machinery of a type I-E CRISPR-Cas system: the
> five-subunit Cascade surveillance complex and the Cas3 nuclease-helicase, with
> Cas1-Cas2 spacer acquisition accessory.

and its description states, in the description rather than a footnote, that this
does not mean the system can interfere with anything, because interference
additionally requires an array that protein markers cannot evidence.

Two further decisions:

- **Cascade is one system with five jointly required components.** The complex
  does not assemble without them, and "four of the five subunits" is not a
  defense call.
- **Adaptation is accessory.** A system interferes using the spacers it already
  has, and *cas1*/*cas2* are lost from many otherwise intact loci.
- **K07475 is refused.** It identifies only the HD nuclease module of a split
  Cas3, which is not evidence of the complete nuclease-helicase. K07012, the
  fused protein, is the accepted marker.

### Recommendation for the array

**Option 2 only on a second demonstrated need.** Broadening the
evidence schema for one example is how a model acquires machinery nobody can
justify later. If a second capability turns up that genuinely needs non-marker
genomic evidence — and defense is where such cases live — the case becomes
architectural rather than anecdotal, and the design should then be:

- a `genomic_feature` evidence kind with its own namespace-like vocabulary
  (`CRISPR_ARRAY`, `TRNA`, `INTEGRATION_SITE`, …);
- an evaluation input that accepts detected features alongside annotations;
- a confidence ordering that treats a detected feature honestly, since a feature
  detector's false-positive rate is a different thing from an orthology
  assignment's;
- traces that show which feature supported which component.

Nothing in the present schema forecloses this. The component-to-evidence link is
already a separate table per model, so a second evidence kind is an addition
rather than a migration of the existing one.

### What must not happen

The current schema *would* accept a `defense_component_marker` row asserting
that some Cas protein accession evidences the array. That would be false, and no
validator can catch it. It is written down here so that a future curator meets
the refusal rather than the convenience.

## What is still deferred

1. **Array-aware CRISPR claims.** Blocked on the evidence model, by choice. The
   design sketch above stands; it needs a second case before it is worth
   building.
2. **CRISPR subtypes other than I-E.** The Cascade accessions used here are
   subtype I-E specific by definition. Types II, III, V and VI need their own
   mechanisms and their own accession review; a *cas1* hit is not evidence of
   any of them.
3. **Type II, III and IV restriction-modification, and the wider defense
   repertoire** — abortive infection, toxin-antitoxin, BREX, Gabija and the rest.
   Each needs the same treatment: what is the mechanism, what makes it complete,
   and can the accessions single it out.
4. **Any claim about an outcome.** "Resists phage" is not curatable from a
   genome: it depends on the invader's counter-measures and on defences no
   database enumerates. Defense GIFTs name mechanisms, and a derived layer is
   where a repertoire-level statement would belong.
