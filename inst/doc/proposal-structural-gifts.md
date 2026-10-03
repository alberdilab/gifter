# Structural GIFTs: curated content, refusals, and open questions

Status: partly implemented. `flagellar_apparatus`, `type_iva_pilus`,
`lpt_lipopolysaccharide_export_apparatus` and
`ribitol_phosphate_wall_teichoic_acid` are curated; the coupling-ion-specific
flagellar traits are **refused** at the current evidence level and are
documented here rather than silently curated.

This proposal is the evidence record for the initial structural pass, not the
complete chronological history. Later attempts involving secretion systems,
NCBIfam and genomic context are indexed under their own rows in
[`catalogue-expansion-attempts.tsv`](catalogue-expansion-attempts.tsv).

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

## 5. Cell-envelope structures assessed 2026-10-02

This pass asked whether S-layers and other cell-wall or cell-envelope structures
can be represented as structural GIFTs. They can, but **cell wall** is not one
capability and should not become one GIFT. The current machinery model already
has the right Boolean layers for a chemically and architecturally defined
structure:

```text
envelope structure = ANY complete architecture
architecture       = ALL required assembly functions
assembly function  = ANY complete system
system             = ALL required components
component          = ANY accepted genomic marker
```

No schema change, anchor or metabolic route is needed. The invariant is that a
positive call must support a complete known way to build the named structure or
machine. It cannot mean merely that a genome carries a characteristic domain,
one precursor enzyme, a generic exporter, or the envelope type with which the
structure is usually associated.

### Decision summary

| Candidate boundary | Decision | Why |
|---|---|---|
| Lpt lipopolysaccharide export apparatus | **Implemented in database 2026.28.1** | Seven named components support one experimentally complete trans-envelope machine and have component-resolving KO and equivalog-grade NCBIfam markers. |
| Proteinaceous S-layer | **Biologically valid; curate only lineage-resolved architectures** | Direct lattice-protein profiles exist, but S-layers are non-homologous and their anchoring and secretion systems differ. Generic SLH-domain or anchoring markers are not specific to an S-layer lattice. |
| Poly(ribitol-phosphate) wall teichoic acid | **Implemented in database 2026.29.1 with two alternative architectures** | The marker-resolved Staphylococcus-type architecture reaches 48 genomes and the W23-type architecture 22. Both were admitted through the explicit biological-importance exception without weakening their required roles. |
| Poly(glycerol-phosphate) wall teichoic acid | **Deferred on marker specificity** | The 168-type KO set is prevalent, but neither KEGG nor NCBIfam distinguishes the WTA TagF polymerase from the W23 homologue that makes glycerol-phosphate polymer outside W23 WTA. |
| Diglucosyldiacylglycerol-anchored poly(glycerol-phosphate) lipoteichoic acid | **Implemented in database 2026.30.1** | Equivalog-grade profiles independently resolve anchor synthesis, LtaA translocation and LtaS polymerisation; the exact structure name makes all three roles required without claiming other LTA architectures. |
| Broad, Listeria-type and other lipoteichoic acids | **Deferred on architecture-resolving evidence** | K19005 cannot distinguish primase requirements, no admitted LtaP profile completes the Listeria design, and Bacillus paralogues and non-type-I chemistry remain unresolved. |
| Peptidoglycan sacculus | **Deferred after dedicated marker and prevalence audit** | Chemotype-resolved precursor sets are measurable, but flippase, polymerase and cross-linking alternatives remain incomplete or marker-ambiguous; extended proxies mostly measure annotation completeness. |
| Named surface polysaccharide, such as hyaluronan | **Open at a narrower boundary** | A polymer-specific synthase can establish synthesis and export, but does not by itself establish surface retention as a capsule. |
| Generic capsule, exopolysaccharide layer, outer membrane or cell wall | **Refused at that breadth** | Each name collapses chemically distinct structures and shared export machinery into a claim the markers cannot support. Narrow named structures remain eligible. |

These are structural claims, not phenotypes. A positive call would not assert
that the layer is expressed, assembled in the sampled condition, protective,
permeability-altering, adhesive or virulent.

### 5.1 Proteinaceous S-layer

#### Defensible claim

> The genome encodes at least one complete curated architecture for a
> proteinaceous, two-dimensional cell-surface lattice, including the
> architecture's lattice-forming subunit and any assembly or anchoring
> components known to be jointly required.

One GIFT may contain alternative architectures because the capability is the
same while the implementations are not. It would deliberately under-call
lineages for which no complete architecture has been curated; it must not fill
those gaps with a generic S-layer-associated domain.

The first two architectures worth a full marker audit are:

```text
Clostridioides SlpA architecture
  lattice and cell-wall attachment: SlpA
  dedicated secretion:              SecA2, if a SlpA-system-specific marker
                                     can be separated from other SecA2 systems
  maturation by Cwp84:               accessory, because uncleaved SlpA still
                                     forms an S-layer

Sulfolobales SlaAB architecture
  outer lattice:                     SlaA
  membrane anchoring/stabilisation:  SlaB
```

SlpA itself forms the *Clostridioides difficile* lattice
([PMID 35217634](https://pubmed.ncbi.nlm.nih.gov/35217634/)). Its processing
protease Cwp84 is not a required structural component: a `cwp84` knockout
retains an S-layer made from uncleaved SlpA
([PMID 19808679](https://pubmed.ncbi.nlm.nih.gov/19808679/)). SecA2 contributes
to SlpA secretion, but the pinned release's `TIGR03714.1` profile describes the
serine-rich glycoprotein SecA2/SecY2 system rather than the *C. difficile*
system; a shared SecA2 name is not enough to join those functions. The pinned
NCBIfam release does contain the direct equivalog `NF033435.1` for SlpA, with
334 RefSeq hits.

In Sulfolobales, SlaA forms the outer lattice and SlaB anchors and stabilises it;
loss of `slaB` disrupts the normal surface layer
([PMID 31455649](https://pubmed.ncbi.nlm.nih.gov/31455649/)). The pinned marker
release contains two SlaA equivalogs, `NF040787.1` and `NF041073.1`, but only a
Metallosphaera-scoped SlaB equivalog, `NF040788.1`. That is enough to motivate a
narrow architecture, not to claim coverage of every archaeal S-layer.

Other direct equivalogs show that further architectures are possible:
`NF050048.1` for the Aeromonas VapA lattice, `NF053619.1` for the Bacteroides
BT1927 lattice, `NF041335.1` for an ArtA-dependent Haloferax S-layer protein and
`NF041431.1` for a Methanomicrobiales S-layer glycoprotein. They are not complete
architectures yet. For example, BT1927 is delivered by an adjacent two-partner
secretion protein, but the pinned export-protein profile is `subfamily`-graded
rather than an admitted equivalog
([PMID 26419879](https://pmc.ncbi.nlm.nih.gov/articles/PMC4611039/)).

#### Marker shortcuts refused

- The S-layer homology domain `PF00395`/InterPro `IPR001119` is a cell-wall
  attachment module, not a lattice identity. *Bacillus anthracis* encodes many
  SLH-domain surface proteins in addition to its two lattice proteins.
- `TIGR03609.1` CsaB modifies the secondary cell-wall polysaccharide used to
  anchor the whole SLH-protein class. It cannot say which anchored protein, if
  any, is the lattice subunit. CsaB-dependent attachment is experimentally
  established, but attachment is not lattice formation
  ([PMID 20603129](https://pubmed.ncbi.nlm.nih.gov/20603129/)).
- `TIGR04399.1` SlaP is an assembly helper for one Bacillus-type accessory Sec
  system. It does not identify the secreted lattice protein.
- Treating a lattice domain and an attachment domain as two components would
  not repair the problem. The evaluator would allow the two markers to occur on
  unrelated proteins because component AND logic does not assert that two
  domains occur on the same gene.

The S-layer candidate therefore stays open, with direct lattice markers and
lineage-specific assembly functions as the only acceptable route to curation.

### 5.2 Lpt lipopolysaccharide export apparatus

This candidate was implemented as `lpt_lipopolysaccharide_export_apparatus` in
database 2026.28.1. Reconstitution showed that LptA
through LptG are necessary and sufficient, with ATP, for membrane-to-membrane
lipopolysaccharide transport
([PMID 29449493](https://pubmed.ncbi.nlm.nih.gov/29449493/)). The curated GIFT
claims:

> The genome encodes the Lpt machinery required to extract lipopolysaccharide
> from the inner membrane, conduct it across the periplasm and insert it into
> the outer leaflet of the outer membrane.

Its architecture maps cleanly onto the current tables:

```text
ARCH_LPT_CANONICAL
  inner-membrane extraction   SYS_LPTBCFG = LptB AND LptC AND LptF AND LptG
  periplasmic bridge          SYS_LPTA    = LptA
  outer-membrane translocon   SYS_LPTDE   = LptD AND LptE
```

KEGG has component-resolving orthologues for all seven: `K09774` LptA,
`K06861` LptB, `K11719` LptC, `K04744` LptD, `K03643` LptE, `K07091` LptF and
`K11720` LptG. On 2026-10-02, 3,426 KEGG organism records carried all seven.
The high co-occurrence is a prevalence check, not evidence of completeness;
the completeness argument comes from the reconstituted machine.

The marker layer also admits eleven component-specific profiles from pinned
NCBIfam `hmm_PGAP/20.0`, all at `equivalog` grade. It refuses the combined
LptF/LptG subfamily, the broad LptA/LptD_N and LptC domains, and the
Pfam-equivalent LptD and LptE profiles. Seventeen current KEGG gene records carry
both `K07091` and `K11720`; this is handled as a fused LptF/G protein whose one
gene can satisfy both separately retained component roles, not by collapsing
the roles into a generic permease. No current KEGG record or primary evidence
supported a corresponding LptA/C fusion architecture.

The boundary excludes lipopolysaccharide precursor synthesis, MsbA, accessory
LptM/YedD proteins, outer-membrane protein insertion by BAM and the outer
membrane as a whole. It is the **Lpt apparatus**, not a proxy for a generic
diderm envelope. `structural_class = secretion_machine` already describes this
boundary, and no new facet term is needed.

The only reported LptC bypass depends on particular suppressor substitutions in
LptF rather than ordinary component presence
([PMID 36541759](https://pubmed.ncbi.nlm.nih.gov/36541759/)). Because gifter does
not model residues, the canonical architecture requires LptC rather than
claiming a second marker-only architecture.

Two further boundary decisions keep the claim honest:

- LptE is not universally indispensable. *Neisseria meningitidis* can transport
  lipopolysaccharide after `lptE` deletion
  ([PMID 21705335](https://pubmed.ncbi.nlm.nih.gov/21705335/)). A generic
  LptD-only system would nevertheless make every LptD marker sufficient in
  every lineage. The alternative therefore remains a documented under-call
  until a marker or other admitted evidence distinguishes the permissive
  architecture.
- LptM stabilises LptD maturation in Enterobacteriaceae
  ([PMID 37821449](https://pubmed.ncbi.nlm.nih.gov/37821449/)), while YedD is
  required for optimal transport in sensitised backgrounds rather than for the
  basal reconstituted machine
  ([PMID 40127101](https://pubmed.ncbi.nlm.nih.gov/40127101/)). Neither is a
  universal required function of `ARCH_LPT_CANONICAL`, and neither is accepted
  as a shortcut marker.

### 5.3 Peptidoglycan sacculus

The sacculus is a meaningful structure, so the candidate is not refused. What
is refused is a shortcut in which MurA--MurF plus one penicillin-binding protein
stands for complete sacculus construction. A dedicated pass on 2026-10-02
tested whether narrower chemotypes repair that problem; none yet has a complete
marker-resolved architecture.

#### Boundary and architecture inventory

A positive claim would have to cover every stage between soluble precursor and
cross-linked sacculus:

| Function | Required distinction | Audit result |
|---|---|---|
| UDP-MurNAc and stem assembly | MurA, MurB, MurC, MurD, chemotype-specific MurE, MurF, Alr, Ddl and MurI | The ordinary and fused roles are marker-resolvable. `K01928` plus the MurE/MurF fusion `K15792` separates meso-DAP incorporation from lysine MurE `K05362`; `K01798` can supply the Alr/MurF fusion. These are precursor evidence, not a sacculus call. |
| Lipid-carrier loading | MraY and MurG | Specific orthologies exist, but completion only reaches lipid II. |
| Lipid II translocation | A complete set of MurJ, Amj and other experimentally valid alternatives | MurJ is marker-resolvable. The pinned Amj profile `NF022450.7` is `PfamAutoEq`, not an admitted equivalog, and MurJ plus Amj is no longer exhaustive. |
| Glycan polymerisation | Vegetative RodA/FtsW partners or a defended class-A-PBP alternative | `K03588` merges FtsW, RodA and sporulation-specific SpoVE, so it cannot evidence vegetative polymerisation. RodA-specific evidence exists, but RodA plus one selected PBP is not an exhaustive sacculus architecture. |
| Peptide cross-linking | Chemotype-compatible D,D- or principal L,D-transpeptidase design | PBP orthologies mix division, elongation and repair-biased roles. `K19236` merges L,D-transpeptidases that create 3-3 links with enzymes that attach Braun lipoprotein, so it cannot license principal sacculus cross-linking. |
| Interpeptide bridge formation | FemX/A/B, MurM/N or another chemistry-specific set where the stem requires it | The individual roles are resolvable, but they cannot be mixed with a direct-cross-link architecture or used to repair an unresolved flippase or polymerase. |

MurJ is a lipid II flippase in *Escherichia coli*
([PMID 25013077](https://pubmed.ncbi.nlm.nih.gov/25013077/)), whereas Amj can
replace it in *Bacillus subtilis*
([PMID 25918422](https://pubmed.ncbi.nlm.nih.gov/25918422/)). Growth after both
activities are removed implies at least one further route
([PMID 40183557](https://pubmed.ncbi.nlm.nih.gov/40183557/)). RodA and FtsW are
SEDS glycan polymerases rather than merely shape proteins
([PMID 28263321](https://pubmed.ncbi.nlm.nih.gov/28263321/)), but the marker
layer must still distinguish them from SpoVE and pair them with compatible
transpeptidation. D,D and L,D cross-linking are genuine alternative designs,
including L,D-dominated cell walls in *Mycobacterium tuberculosis* and
*Clostridioides difficile*
([PMID 25006233](https://pubmed.ncbi.nlm.nih.gov/25006233/)).

#### Prevalence and utility

The audit used the stored 11,908-prokaryote KEGG frame. A complete meso-DAP
precursor proxy reaches 7,271 genomes and a lysine precursor proxy 432. That
large meso-DAP count confirms that the conserved Mur inventory mostly measures
whether core precursor enzymes were annotated. An intentionally unsafe extended
meso-DAP proxy requiring MurJ, RodA, PBP2, merged `K03588`, FtsI and a class-A
PBP reaches 3,538 genomes, with another 1,579 one role short. MurI, MurJ, FtsI
and a class-A PBP dominate those near-complete failures, showing sensitivity to
unresolved alternatives and annotation rather than a defended biological
boundary. A lysine/pentaglycine proxy reaches only four unexpected
*Macrococcus* or *Salinicoccus* genomes and misses expected *Staphylococcus*
references at the unresolved flippase step.

These are diagnostics, not architectures. Full counts and marker decisions are
retained in
[`lta-peptidoglycan-prevalence.tsv`](../../data-raw/reference/lta-peptidoglycan-prevalence.tsv)
and
[`lta-peptidoglycan-marker-audit.tsv`](../../data-raw/reference/lta-peptidoglycan-marker-audit.tsv).
No taxon, neighbourhood, absence pattern or merged marker was used to rescue a
proxy.

#### Decision and exact retrigger

No peptidoglycan GIFT is added. The next pass should start with one named
chemotype, not a pan-bacterial claim, and must supply: an experimentally
defended minimal precursor-to-sacculus design; equivalog-grade evidence for
every flippase, polymerase and transpeptidase alternative it accepts; explicit
separation of vegetative SEDS proteins from SpoVE; and bridge chemistry that
cannot hybrid-complete with an incompatible stem. A new Amj equivalog alone is
not sufficient while the third *B. subtilis* translocation activity remains
unresolved.

### 5.4 Wall and lipoteichoic acids

#### Wall teichoic acid: dedicated pass 2026-10-02

The defensible public boundary is **poly(glycerol-phosphate) wall teichoic
acid** or **poly(ribitol-phosphate) wall teichoic acid**, not one broad
`wall_teichoic_acid` GIFT. The backbone chemistry is a meaningful distinction
that the polymer-specific machinery can in principle evidence, while a broad
claim would conceal exactly the ambiguity found in the marker audit. The two
ribitol-phosphate implementations below are alternative architectures of one
chemistry-specific GIFT; they are not separate public capabilities.

A positive call at either boundary would mean that the genome encodes one
complete architecture spanning the undecaprenyl-linked WTA linkage unit, a
chemistry-specific polymer, TagGH export and LCP-family attachment to
peptidoglycan. It would not mean that WTA is expressed, decorated, abundant or
assembled in a sampled condition, nor would it imply lipoteichoic acid,
antibiotic resistance, virulence or a cell-wall phenotype.

The experimentally supported function inventory is:

| Function | Required inventory | Curation consequence |
|---|---|---|
| UDP-ManNAc donor supply | MnaA or a demonstrated replacement such as Cap5P | Required. Removing `mnaA` abolishes WTA in *S. aureus*, while Cap5P can provide a compensatory activity in that species ([PMC 4856313](https://pmc.ncbi.nlm.nih.gov/articles/PMC4856313/)); `K01791` is only a broad donor-enzyme proxy. |
| Linkage-unit construction | TagO, TagA and TagB | Required. TagB is the glycerol-phosphate primase on the linkage unit, not the backbone polymerase ([PMID 16150696](https://pubmed.ncbi.nlm.nih.gov/16150696/)). |
| Glycerol-phosphate donor supply | TagD | Required for the 168-type glycerol architecture and for the glycerol-phosphate linkage step in the two ribitol architectures. |
| Chemistry-specific priming and elongation | 168-type TagF; *S. aureus* TarF plus bifunctional TarL; or W23 TarK plus TarL | Required as the architecture-discriminating function. *S. aureus* TarL can prime and polymerise the ribitol-phosphate chain ([PMID 18281399](https://pubmed.ncbi.nlm.nih.gov/18281399/)); W23 instead uses TarK to prime and TarL to extend it ([PMID 21035733](https://pubmed.ncbi.nlm.nih.gov/21035733/)). |
| Ribitol-phosphate donor supply | TarI and TarJ | Required only by the ribitol architectures. |
| Export | TagG and TagH jointly | Required; the two components form the WTA ABC transporter. |
| Peptidoglycan attachment | At least one architecture-appropriate LCP ligase | Required. Redundant LCP proteins can substitute for one another, but eliminating all three in *S. aureus* releases rather than tethers the polymer ([PMID 23935043](https://pubmed.ncbi.nlm.nih.gov/23935043/)). |

TagE-mediated glucosylation, TarM/TarS/TarP glycosylation, DltABCD-mediated
D-alanylation, regulators, autolysins and resistance determinants are not
required for the named backbone-and-attachment capability. They are decorations
or downstream context and would be accessory at most. `K19005` LtaS evidence is
also inadmissible: it supports the separate lipoteichoic-acid question below,
not WTA.

#### Marker and prevalence audit

The KO inventory was checked against current official KEGG definitions on
2026-10-02. The common proxy set was `K02851` TagO/WecA/Rfe, `K05946` TagA,
`K01791` MnaA/WecB, `K00980` TagD, `K21285` TagB, `K09692` TagG, `K09693`
TagH and `K01005` LCP. These accessions are acceptable only as components of a
complete architecture; none establishes WTA or its chemistry alone. In
particular, `K02851`, `K01791` and `K01005` also cover functions in other
cell-envelope glycan systems.

Co-occurrence was measured over the 11,949-genome stored KEGG frame, including
11,908 prokaryotic entries. Although the stored matrix is KO-only, a targeted
screen can give an exact NCBIfam-aware count: first intersect every required KO,
then run the safe NCBIfam profiles on the exact KO-assigned polymerase sequences
from every genome in that intersection. The resulting profile-positive set is
necessarily a subset of the full-frame KO proxy; taxonomy never substitutes for
a marker. `data-raw/wta_ncbifam_prevalence.R` implements this screen and retains
only aggregate results in
[`wta-ncbifam-prevalence.tsv`](../../data-raw/reference/wta-ncbifam-prevalence.tsv).

| Candidate architecture | Polymer-specific proxy added to the common set | Complete KO proxy sets | Disposition |
|---|---|---:|---|
| *B. subtilis* 168-type poly(glycerol-phosphate) WTA | `K09809` TagF | 267 | Deferred on specificity. `K09809` also marks the W23 TagF homologue that makes glycerol-phosphate polymer but is not used for W23 ribitol-phosphate WTA. The proxy therefore calls W23 positive for the wrong backbone; it also completes a *Sulfitobacter donghicola* envelope-glycan set. |
| *S. aureus*-type poly(ribitol-phosphate) WTA | `K21591` TarF, `K21030` TarI, `K05352` TarJ and `K18704` TarL | 49 KO proxy; 48 marker-resolved | Curated in `ARCH_RIBITOL_WTA_STAPHYLOCOCCUS` under the biological-importance exception. All 49 proxy genomes pass the `NF041712.1` *S. aureus* TarF equivalog and 48 pass the `NF041713.1` Staphylococcus TarL equivalog; only the two equivalogs, not their broader KO proxies, evidence the discriminating system. |
| *B. subtilis* W23-type poly(ribitol-phosphate) WTA | `K21030` TarI, `K05352` TarJ, `K21592` TarK and `K18704` TarL | 22 | Curated in `ARCH_RIBITOL_WTA_W23` under the biological-importance exception. Requiring TarK **and** TarL preserves the distinct W23 primase/elongase design despite its rarity. |

The 168 result demonstrates why prevalence cannot rescue an over-broad marker:
W23 itself carries the entire KO proxy even though the biochemical comparison
shows that its `K09809` homologue is not the polymerase for its WTA. The pinned
NCBIfam 20.0 release does not repair this. An exhaustive metadata search finds
only `NF016357.7`, a domain-graded CDP-glycerol
glycerophosphotransferase family profile, and `NF041712.1`, the equivalog for
the distinct *S. aureus* TarF primase in ribitol-WTA synthesis. Neither is a
168-type TagF equivalog; the result is retained in
[`wta-tagf-marker-audit.tsv`](../../data-raw/reference/wta-tagf-marker-audit.tsv).

The Staphylococcus screen searched 146 exact `K21591` and `K18704` protein
sequences with both equivalogs at their profile-specific gathering thresholds.
`NF041712.1` passes in all 49 KO-proxy genomes and `NF041713.1` in 48. The one
remaining TarL-like sequence scores 770 bits against the profile's 1,000-bit
cutoff and is not promoted by taxonomy or by relaxing the curated threshold.
Dropping TagD raises the original KO proxy to 57 genomes and dropping TarF
raises it to 148, identifying those steps as the principal near-complete
patterns without making either omission biologically valid.

Database 2026.29.1 implements one public
`ribitol_phosphate_wall_teichoic_acid` GIFT with the Staphylococcus and W23
designs as alternative complete architectures. The standing prevalence screen
would ordinarily defer both, but the 2026-10-02 biological-importance decision
admits them at 48 and 22 genomes respectively. That exception changes curation
priority, not completeness: every shared linkage, donor, export and attachment
function remains required, as do the architecture-specific TarF/TarL or
TarK/TarL pairs. The glycerol candidate remains deferred until an admitted
accession distinguishes the 168-type TagF polymerase from the W23 non-WTA
homologue. No schema change is required.

#### Lipoteichoic acid: dedicated pass 2026-10-02

The defensible public boundary is
**diglucosyldiacylglycerol-anchored poly(glycerol-phosphate) lipoteichoic
acid**, not broad `lipoteichoic_acid`, `type_i_lipoteichoic_acid` or one
unqualified LtaS call. The exact anchor makes the three experimentally supported
functions jointly meaningful:

| Function | Required system | Boundary consequence |
|---|---|---|
| Glycolipid-anchor synthesis | Processive YpfP/UgtP-family diglucosyldiacylglycerol synthase | Required because the GIFT names this anchor. `ypfP` loss leaves shorter diacylglycerol-anchored material, not the named structure ([PMID 17640274](https://pubmed.ncbi.nlm.nih.gov/17640274/)). |
| Anchor translocation | LtaA | Required for presenting the disaccharide anchor at the outer leaflet; the transport mechanism is directly supported ([PMID 32367070](https://pubmed.ncbi.nlm.nih.gov/32367070/)). |
| Backbone polymerisation | LtaS | Required to transfer glycerol phosphate from phosphatidylglycerol and build the chain ([PMID 17483484](https://pubmed.ncbi.nlm.nih.gov/17483484/)). |

The YpfP/LtaA anchor pathway follows the original *Staphylococcus aureus*
genetic and biochemical evidence
([PMID 17209021](https://pubmed.ncbi.nlm.nih.gov/17209021/)). Residual polymer
after `ypfP` or `ltaA` disruption does not justify making either role optional:
it changes the membrane anchor and therefore falls outside this deliberately
narrow structure name.

#### Marker and prevalence audit

The admitted architecture uses only three NCBIfam `hmm_PGAP/20.0` equivalogs:
`NF010134.0` for the processive diglucosyldiacylglycerol synthase,
`NF047396.1` for LtaA and `NF053595.1` for LtaS. Their Staphylococcaceae or
Caryophanales seed scopes are properties of the profiles, not taxonomic gates
in gifter. `K03429` is retained only as a glycolipid-enzyme prevalence proxy.
`K19005` is not admitted because KEGG associates it with more than the named
LTA chemistry and it does not distinguish primase-dependent from
primase-independent LtaS-family systems.

In the 11,908-prokaryote reference frame, `K19005` reaches 1,350 genomes,
`K03429` 1,097 and their intersection 581. Searching the exact KO-assigned
proteins at the NCBIfam gathering thresholds leaves 129 genomes with both the
LtaS and anchor-synthase profiles. Of 128 downloadable whole proteomes, 127
also carry the LtaA profile. The set includes *Sulfitobacter donghicola*, whose
three matches score at or above the Staphylococcus controls. That genome is
kept positive: an unfamiliar envelope context cannot be used as negative
evidence against three admitted markers. One *Staphylococcus pseudintermedius*
proteome lacks LtaA evidence and one *S. aureus* assembly was unavailable, so
neither is silently completed. The 127 is an observed lower bound rather than
an exact full-frame NCBIfam prevalence, but it establishes useful variation and
does not resemble a near-universal annotation-completeness proxy.

DltABCD-mediated D-alanylation and LTA glycosyltransferases decorate an existing
polymer and are excluded from core completeness. They neither create nor
identify the named anchor-and-backbone structure.

#### Alternatives deliberately not implemented

The Listeria design remains separate. LtaP primes and LtaS elongates the chain
([PMID 19682249](https://pubmed.ncbi.nlm.nih.gov/19682249/)); structural work
supports distinct primase and synthase roles
([PMID 25128528](https://pubmed.ncbi.nlm.nih.gov/25128528/)). NCBIfam 20.0 has
no admitted LtaP equivalog, and its matching glycolipid-anchor inventory has not
been completed. The forbidden shortcut therefore remains forbidden: gifter
does not encode `LtaS OR (LtaP AND LtaS)` from the shared `K19005` marker. The
curated architecture avoids that shortcut through its independently required
YpfP/LtaA anchor system, not through taxonomy.

The multiple *Bacillus* LtaS-family proteins, including primase-like and backup
activities, do not yet form separately evidenced minimal architectures.
Non-type-I LTAs use different anchor or backbone chemistry and cannot be
subsumed by poly(glycerol-phosphate) evidence. Both remain future candidates.
They unblock only when every required function has a specific admitted marker
and no shorter alternative automatically completes the longer design.

Database 2026.30.1 therefore adds
`diglucosyl_diacylglycerol_anchored_lipoteichoic_acid` with one architecture,
three required functions, three one-component systems and no KO shortcut. Full
aggregate results are retained in the two LTA/peptidoglycan audit tables linked
from §5.3.

### 5.5 Capsules and other extracellular polysaccharide layers

`capsule` and `exopolysaccharide layer` are descriptions of location and form,
not one biosynthetic architecture. Wzx/Wzy repeat-unit assembly and Wza/Wzc
export are shared across capsular polysaccharides, O antigens and extracellular
polymers. Wzx specificity follows the repeat-unit chemistry
([PMID 24532778](https://pubmed.ncbi.nlm.nih.gov/24532778/)), while Wzc homologues
participate in both capsular and extracellular-polysaccharide systems
([PMID 12426330](https://pubmed.ncbi.nlm.nih.gov/12426330/)). A generic exporter
therefore cannot license a generic capsule GIFT.

Chemically named polymers can still be considered one at a time. Hyaluronan is
the cleanest initial example because HasA is a polymer-specific processive
synthase, and the streptococcal `hasABC` locus is required for capsule
production
([PMID 7629171](https://pubmed.ncbi.nlm.nih.gov/7629171/)). The remaining
boundary question is important: HasA establishes hyaluronan synthesis coupled
to export, but does not by itself establish that the polymer is retained as a
surface capsule. `hyaluronan_surface_polymer_synthesis` may be defensible after
a full architecture audit; `hyaluronan_capsule` is not yet licensed by the
marker alone.

### Outcome

This assessment produced `lpt_lipopolysaccharide_export_apparatus` in database
2026.28.1, `ribitol_phosphate_wall_teichoic_acid` in database 2026.29.1 and
`diglucosyl_diacylglycerol_anchored_lipoteichoic_acid` in database 2026.30.1,
without a schema change. The existing structural model represents the Lpt
machine as three required functions, the ribitol-WTA capability as two
alternative architectures sharing six functions and differing in one
chemistry-specific polymerisation function, and the narrow LTA structure as
three jointly required anchor-synthesis, translocation and polymerisation
functions.
S-layers remain viable only as alternative, lineage-resolved architectures;
the peptidoglycan sacculus, broad and Listeria-type LTA, and named extracellular
polymers remain open with explicit blockers. The 168-type glycerol-phosphate WTA
candidate remains blocked on marker specificity; rarity no longer blocks either
ribitol architecture. The LptE-independent Neisseria implementation is an
explicit under-call. Generic cell-wall, capsule, EPS, broad LTA and
outer-membrane claims are closed at that breadth.
