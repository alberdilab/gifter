# Structural GIFTs: curated content, refusals, and open questions

Status: partly implemented. `flagellar_apparatus`, `type_iva_pilus`,
`lpt_lipopolysaccharide_export_apparatus`,
`ribitol_phosphate_wall_teichoic_acid` and `archaellum` (§6.1) are curated; the coupling-ion-specific
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

1. ~~Should a structural GIFT be allowed to declare a *composition*
   relationship with another GIFT, the way metabolic GIFTs compose through
   anchors?~~ **Closed 2026-10-03: no.** The condition this question waited on
   has now happened three times over, and each time the answer was that nothing
   was needed. `type_iii_secretion_injectisome` overlaps `flagellar_apparatus`
   by homology and is separated by marker specificity (§7). `archaellum` and
   `type_iva_pilus` share the class III peptidase outright, one protein serving
   two machines, and that is expressed by accepting `K02654` on each GIFT's own
   component row (§6.1). `type_ii_secretion_system` shares the same peptidase
   with the same pilus. In none of the three did duplication cost anything: each
   GIFT states its own required inventory, and `trace_gift()` already shows the
   one gene supporting both components. A composition table would instead assert
   that two machines overlap, which no evaluation reads and no query has asked
   for. Metabolic GIFTs compose because an anchor is a *public biological
   interface* that another capability can start from; a shared subunit is an
   implementation detail of two independent machines. The rule, and the
   three-way distinction between a fused protein, a shared component and an
   ambiguous marker, is now stated in
   [the architecture guide](architecture.md#shared-components-and-the-ambiguity-that-is-not-a-marker-defect)
   and enforced by a test: two structural GIFTs sharing a component accession
   must each require a function the other does not.
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

## 6. Prevalent machines: initial assessment 2026-10-03

Attempt `GEA-20261003-STRUCTURAL-MACHINES`. This is a screen, not a curation
pass: it adds no GIFT. Nine candidates chosen from domain knowledge were tested
for three things -- whether every required function has a marker that
separates the machine from its homologues, whether a small subunit turns the
call into an annotation-completeness proxy, and whether the call would be
informative.

KO definitions were read from the KEGG list cached on 2026-08-22 and gene links
were fetched on 2026-10-03. NCBIfam grades are from `hmm_PGAP/20.0`; only
`equivalog` and `equivalog_domain` count as admitted, so an `exception`,
`subfamily`, `domain` or `PfamEq` profile is recorded as unavailable. Prevalence
is a KO proxy over the stored frame, regenerated by
`data-raw/structural_machines_prevalence.R` into
`data-raw/reference/structural-machines-{ko,proxy}-prevalence.tsv` and
`structural-machines-homology-overlap.tsv`. No proxy set below is a curated
architecture.

**Denominator.** The stored frame flags 11,908 genomes as prokaryotic, but the
flag is a genus-name filter. The KEGG organism hierarchy places 10,143 of them
in Bacteria, 470 in Archaea and 1,290 in Eukaryotes (5 unresolved). Percentages
below use the bacterial or archaeal denominator. `K07277`, which merges BamA
with eukaryotic SAM50/TOB55, is how this surfaced: 1,214 of its 7,287 genomes
are not bacteria.

**Shared homologous components.** The type III/type VI session
(`GEA-20261003-SECRETION-T3-T6`) had not yet written its rule for two structural
GIFTs that share homologous components when this screen ran. The type II
secretion, Tad and type IV secretion recommendations are conditional on it.

### Summary

| Candidate | Recommendation | KO-proxy prevalence | Deciding evidence |
|---|---|---|---|
| Archaellum | Curated 2026-10-03 as `archaellum` (§6.1) | 256 of 470 archaea (54%) plus 2 Chloroflexota; curated architecture 253 archaea plus 2 Chloroflexota | Archaellin, FlaF, FlaG and FlaH are machine-specific; FlaI and FlaJ are not on their own |
| Tad pilus, diderm | Curate, KO-only | 1,631 bacteria (16%) | Eight functions with Tad-specific KOs; no NCBIfam equivalog except CpaB |
| Type II secretion system | Curate once the shared-homologue rule exists | 1,571 bacteria (15%) | Every function has its own KO and an NCBIfam equivalog; GspC is the weak component |
| Gas vesicles | Defer | GvpA only: 546 bacteria, 59 archaea | Five of eight required proteins have no admitted marker |
| BAM complex | Refuse | BamA 6,073 bacteria (60%); BamA+BamD 5,262 | Tracks the diderm envelope; 4,321 of 4,359 LptD genomes carry BamA |
| Curli | Curate, low priority | 252 bacteria (2.5%), 250 Enterobacteria | All five functions have KOs and equivalogs; CsgA is the gap outside Enterobacteria |
| Chaperone-usher pili | Refuse the class; defer named pili | Usher+chaperone 1,783; type 1 179; Pap 11 | The usher KO merges FimD, MrkC, HtrE and CssD; the subunit is routinely missed |
| Type IV secretion / conjugation | Refuse the class; defer named apparatus | VirB/D4 91; Trb 643; F 75; Dot/Icm 33 | KEGG covers three of eight mating-pair-formation classes; function is not readable from the apparatus |
| Bacterial microcompartments | Refuse the class; curate the beta-carboxysome | Any shell 518; beta-carboxysome 160 | Shell KOs are named for a substrate the shell protein cannot evidence |

### 6.1 Archaellum

**Curated 2026-10-03** as `archaellum` (attempt `GEA-20261003-ARCHAELLUM`,
database 2026.32.1, change `DBC-20261003-ARCHAELLUM`). The screen above
recommended it; this subsection records the curation decision and the evidence
that settled its five open questions.

> The genome encodes the machinery required to assemble an archaellum:
> archaellin, a class III signal peptidase that processes it, the FlaF/FlaG
> stator, the FlaI motor ATPase with its FlaH regulator, and the FlaJ membrane
> platform.

The claim is assembly machinery. It excludes swimming, taxis, the direction of
rotation and its switching, expression, and archaellin glycosylation. Gene
names follow the `fla` designations KEGG uses. The `arl` names were proposed by
Pohlschroder *et al.* ([PMID 29912330](https://pubmed.ncbi.nlm.nih.gov/29912330/)),
after the structure itself was renamed
([PMID 22613456](https://pubmed.ncbi.nlm.nih.gov/22613456/)).

```text
ARCH_ARCHAELLUM_CORE
  required   SF_ARCHAELLUM_FILAMENT          archaellin            K07324 | K07325
             SF_ARCHAELLUM_SIGNAL_PEPTIDASE  FlaK/PibD             K07991 | NF040695.1
                                             or bacterial PilD     K02654 (putative)
             SF_ARCHAELLUM_STATOR            FlaF + FlaG           K07329 | NF052590.1 ; K07330 | NF052591.1
             SF_ARCHAELLUM_MOTOR             FlaI + FlaH           K07332 (putative) | NF058587.1 ; K07331 | NF052589.1
             SF_ARCHAELLUM_PLATFORM          FlaJ                  K07333 (putative) | NF004703.2 | NF004704.2 | NF004705.1
  accessory  SF_ARCHAELLUM_SWITCH_COMPLEX    FlaC + FlaD + FlaE    K07822 | K23986 ; K07327 ; K07328 | K23986
             SF_ARCHAELLUM_FLAX_RING         FlaX                  NF058591.1
```

The required inventory is the one the *Methanococcus maripaludis*
([PMID 17887963](https://pubmed.ncbi.nlm.nih.gov/17887963/)) and *Sulfolobus
acidocaldarius* ([PMID 22081969](https://pubmed.ncbi.nlm.nih.gov/22081969/))
deletion series share. FlaF and FlaG form one stator complex
([PMID 34912317](https://pubmed.ncbi.nlm.nih.gov/34912317/)), so they are one
two-component system rather than two functions. FlaH and FlaI are one motor
system for the same reason, and FlaJ is the platform.

#### 1. Homology with archaeal type IV pili

Measured, not assumed. Every one of the 5,093 proteins KEGG assigns to an
archaellum orthology in the frame was searched with the archaellum equivalogs
and with contrast profiles for UpsF (`NF046075.1`), the bindosome BasE/BasF
(`NF053672.1`, `NF053673.1`) and EppA (`NF053826.1`), all at their gathering
thresholds.

- `K07332` holds 885 proteins in the 256 archaea that complete the KO core.
  Only 268 of them pass the FlaI equivalog `NF058587.1`, about one per genome,
  and 17 are bindosome BasE; the remaining 597 match no archaellum profile.
  Among the 192 archaea without the core, 391 of 425 `K07332` proteins pass no
  archaellum profile.
- `K07333` behaves the same way: 267 of 858 proteins in core genomes pass an
  ArlJ equivalog, and the orthology also holds 28 UpsF and 17 BasF platforms.
- The control genomes show the same thing in KEGG's own annotation:
  *Haloferax volcanii* `pilB3` (HVO_1034) is assigned to `K07332`, and
  *S. acidocaldarius* carries three `K07332`/`K07333` pairs. Only one of those
  pairs (Saci_1173/1172) lies in the fla locus.
- The 33 core-lacking archaea in which a `K07332` protein passes the FlaI
  equivalog are archaellum loci missing one orthology, not pilus systems. 20 of
  them have archaellin, FlaG, FlaH, FlaI and FlaJ and lack only the FlaF KO,
  and 24 also pass an ArlJ equivalog. The other 159 core-lacking genomes carry
  only pilus-type paralogues.

**Decision.** `K07332` and `K07333` remain required components inside the
conjunction, at `putative` confidence. Within the conjunction they are almost
always right: 252 of the 256 core genomes carry a protein passing the FlaI
equivalog, and 253 one passing an ArlJ equivalog. The accession alone still
cannot separate FlaI from a pilus ATPase, so a KO-only call reports `putative`;
the equivalogs, which pass no protein that a pilus or bindosome profile claims,
raise it to `high-confidence`. The machine is identified by archaellin, FlaF,
FlaG and FlaH. No combination of FlaI, FlaJ and a peptidase fires the GIFT, and
a test enforces that.

#### 2. The class III signal peptidase

Archaellin is not assembled without processing: disrupting *flaK* abolishes
flagellation in *M. voltae*
([PMID 14622420](https://pubmed.ncbi.nlm.nih.gov/14622420/)). The function is
therefore required. Its enzyme is a **shared component**: PibD also processes
pilins and other class III substrates
([PMID 12813086](https://pubmed.ncbi.nlm.nih.gov/12813086/)). That is one
protein serving several machines, not an ambiguous marker, so the function
contributes no machine specificity.

`K07991` covers both forms: euryarchaeal FlaK (*M. maripaludis* MMP0555,
symbol `flaK`) and the broad-specificity PibD (*S. solfataricus* SSO0131,
*H. volcanii* HVO_2993, symbol `pibD`). It is not clean. In each of the 22
archaellum-encoding Methanococcales it also holds the pilin-specific EppA,
which does not cleave prearchaellins
([PMID 17114255](https://pubmed.ncbi.nlm.nih.gov/17114255/)). Every one of
those 22 genomes also carries a `K07991` protein passing the FlaK equivalog
`NF040695.1`, so no call in the frame rests on EppA. The two Methanococcales
carrying only EppA lack the core anyway. `K07991` stays `curated` with that
merge stated in its notes, and `NF053826.1` (EppA) is refused for this
component.

Archaellum-encoding Chloroflexota carry no archaeal-type peptidase orthology.
Their processing enzyme is reported as an archaeal-like PibD in the SAR202
clade and a bacterial-type PilD elsewhere
([PMID 40962902](https://pubmed.ncbi.nlm.nih.gov/40962902/)), and KEGG files
both frame examples under `K02654`. `K02654` is therefore accepted as an
alternative system (`SYS_ARCHAELLUM_PILD`) at `putative` confidence. That PilD
processes archaellin is the authors' inference, not a measurement. `K02654`
occurs in no archaeon of the frame, so it adds no archaeal call. Its use by
`type_iva_pilus` is unchanged.

#### 3. Architecture shape

There is one core architecture. FlaC/D/E and FlaX are accessory functions, in
the same position as PilT retraction in `type_iva_pilus`. Alternative
architectures were rejected because the lineage functions are lineage-restricted
in a way that would measure taxonomy or annotation:

| Lineage, core-complete genomes | FlaC/D/E orthologies carried |
|---|---|
| Methanococcales (22) | FlaC+FlaD+FlaE in 19; FlaD+FlaE in 3 |
| Thermococcales (33) | FlaC+FlaD only |
| Halobacteriales (93) | the FlaCE fusion in 92; no FlaD orthology in any of the 93 |
| Methanosarcinales (35) | none in 22; FlaD only in 13 |
| Methanomicrobiales (19), Sulfolobales (27), Nitrososphaerota (11), Chloroflexota (2) | none |

FlaC/D/E are required for archaellation in *M. maripaludis*, but they are the
euryarchaeal switch complex that receives chemotaxis input through CheF
([PMID 32416640](https://pubmed.ncbi.nlm.nih.gov/32416640/)), and switching is
outside the claim. FlaX is required in *S. acidocaldarius* but has no KEGG
orthology. Its equivalog `NF058591.1` is restricted to Sulfolobaceae, has 25
RefSeq hits and passes none of the KO-assigned proteins in the frame. Under
the rule that no architecture may depend on a function the frame cannot
measure, FlaX could only be accessory.

Consequences:

- **Halobacteria.** All 93 core-complete haloarchaea are called. The accessory
  switch complex is reported incomplete in every one of them, because the
  FlaCE fusion supports FlaC and FlaE but KEGG assigns none of them a FlaD.
- **Nitrososphaerota.** All 11 core-complete genomes are called. Under
  alternative euryarchaeal and crenarchaeal architectures they would complete
  neither, because they carry neither FlaC/D/E nor a measurable FlaX.
- **Over-call risk.** A Methanococcales genome with the core but without
  FlaC/D/E would be called, although the *M. maripaludis* deletions say it
  cannot assemble an archaellum. No such genome exists in the frame: all 22
  carry FlaD, and 19 carry all three. A FlaX-less Sulfolobales genome carries
  the same risk, but the frame cannot measure it.

#### 4. Archaellin marker

`K07325` is defined as `flaB, flgA`. The `flgA` there is the historical
haloarchaeal archaellin name, not bacterial FlgA (`K02386`). 752 of its 758
frame proteins match the archaeal-type flagellin family (Pfam `PF01917`), and
none matches the FlgA P-ring chaperone family `PF13144`. All 14 bacterial
`K07325` proteins belong to the two Chloroflexota, and 13 of them match
`PF01917`. `K07324` and `K07325` are accepted as `curated`.

`TIGR02537.2` is refused. It is a `domain` profile, and by its own description
it covers archaeal type IV pilins. `PF01917` is not admissible either: it is
Pfam, and it also matches 146 FlaF and 298 FlaG proteins, which share the class
III N-terminus.

#### 5. The Chloroflexota positives

The two bacterial calls are *Dehalogenimonas* sp. WBC-2 (`dew`,
Dehalococcoidales) and *Ca.* Lucifugimonas marina (`lmaj`, SAR202). Both carry
a contiguous locus with archaellin, FlaG, FlaF, FlaH, FlaI and FlaJ
(DGWBC_1609–1616; GKN94_13710–13750). Both FlaI proteins pass the FlaI
equivalog, and both genomes carry `K02654`. Their markers hold, so both are
kept, at `putative` confidence.

The experimental support is for the lineage, not for these two genomes.
PMID 40962902 solved the structure of the *Litorilinea aerophila* archaellum
and showed its assembly and swimming function. It reported complete archaellum
loci in 244 Chloroflexota, and noted that the cultivated SAR202 isolates showed
no surface filaments. PMID 42388304 describes how the *L. aerophila* envelope
anchors that archaellum. *L. aerophila* is not in the frame. Neither statement
changes a call, which claims encoded machinery only.

#### Markers

| Accession | Component | Decision | Reason |
|---|---|---|---|
| `K07324`, `K07325` | archaellin | curated | All assignments are archaellins (PF01917); no FlgA |
| `K07329`, `K07330` | FlaF, FlaG | curated | Track archaellin: 266 and 283 archaea against 290 with an archaellin orthology |
| `K07331` | FlaH | curated | 288 archaea against 290 with an archaellin orthology |
| `K07332` | FlaI | putative | Holds pilus and bindosome ATPases; only inside the conjunction |
| `K07333` | FlaJ | putative | Holds UpsF/BasF-type platforms; only inside the conjunction |
| `K07991` | FlaK/PibD | curated | Covers FlaK and PibD; the EppA merge in Methanococcales is measured and harmless in the frame |
| `K02654` | bacterial PilD | putative | Only peptidase of archaellum-encoding Chloroflexota; processing inferred |
| `K07822`, `K07327`, `K07328`, `K23986` | FlaC/D/E (accessory) | curated | FlaCE fusion supports FlaC and FlaE |
| `NF058587.1` | FlaI | high-confidence | Equivalog; passes no pilus or bindosome protein |
| `NF004703.2`, `NF004704.2`, `NF004705.1` | FlaJ | high-confidence | Equivalogs for Methanobacteriota, Methanobacteriati and Thermoproteati |
| `NF052589.1` | FlaH | high-confidence | Equivalog, Archaea range |
| `NF052590.1`, `NF052591.1` | FlaF, FlaG | high-confidence | Equivalogs, Methanobacteriota range only |
| `NF040695.1` | FlaK | high-confidence | Equivalog, Methanococcales; separates FlaK from EppA |
| `NF058591.1` | FlaX (accessory) | high-confidence | Equivalog, Sulfolobaceae, 25 hits; not measurable in the frame |
| `TIGR02537.2` | archaellin | refused | `domain` grade; covers archaeal type IV pilins |
| `NF053826.1` | peptidase | refused | EppA processes pilins, not archaellins |
| `NF046075.1`, `NF053672.1`, `NF053673.1` | — | refused | UpsF and bindosome machinery; contrast profiles only (BasE/BasF are `exception` grade) |
| `PF01917`, `PF13144` | — | not admissible | Pfam diagnostics only; PF01917 also matches FlaF and FlaG |

#### Prevalence and controls

In the KEGG frame, 253 of 470 archaea (53.8%) and 2 of 10,143 bacteria
complete the architecture. Prevalence is never stated against the 11,908-genome
`prokaryote` flag. Twenty-five archaea are exactly one function short:

| Missing function | Genomes | Lineages |
|---|---|---|
| FlaF/FlaG stator | 17 | Desulfurococcales 6, Thermococcales 3, unclassified Thermoplasmatota 2, and one each in Halobacteriales, Methanosarcinales, Caldarchaeales, Promethearchaeales, Methanosuratincolales and Sulfolobales |
| FlaI/FlaH motor | 3 | Halobacteriales |
| class III signal peptidase | 3 | Thermoplasmatales 2, Methanosarcinales 1 (no `K07991`) |
| archaellin | 1 | Halobacteriales |
| FlaJ platform | 1 | Sulfolobales |

The stator gap is FlaF in 14 of the 17 genomes, FlaG in 2 and both in 1. They
span Thermoproteota (8), Methanobacteriota (5), Thermoplasmatota (2),
Nitrososphaerota and Promethearchaeota. KEGG assigns no FlaF orthology in those
loci, and outside Methanobacteriota the FlaF and FlaG equivalogs do not reach.
These are probable under-calls, not evidence of absence. The accessory switch complex is complete in 19 of the 255 called
genomes, all Methanococcales, and FlaX in none, because the frame carries no
NCBIfam annotation.

Named controls, re-read from KEGG on 2026-10-03 and evaluated by
`evaluate_gifts()`:

- *M. maripaludis* S2, *S. acidocaldarius* DSM 639 and *H. volcanii* DS2
  complete the archaellum at `putative` confidence. *M. maripaludis* also
  supports the switch complex.
- *Escherichia coli* K-12 MG1655 and *Bacillus subtilis* 168 complete
  `flagellar_apparatus` and not the archaellum. *E. coli* supports only the
  shared peptidase function.

**Reference frames.** No stored frame in `reference_frames.tsv` filters on
`type = structural` or on `structural_class`, so none changes denominator. The
unstored default frames "all curated GIFTs" and "structural GIFTs" each gain
one member. Both are unbounded, so only richness changes, and no fraction is
reported against either.

Aggregates are in `data-raw/reference/archaellum-*.tsv`, regenerated by
`data-raw/archaellum_ncbifam_prevalence.R`.

### 6.2 Tad (Flp) pilus

Claim: the genome encodes the machinery to assemble a Tad pilus in a diderm
envelope. It excludes adherence and biofilm formation. Every gene from *flp-1*
to *tadG* is required in *Aggregatibacter actinomycetemcomitans*
([PMID 11029439](https://pubmed.ncbi.nlm.nih.gov/11029439/),
[PMID 11359562](https://pubmed.ncbi.nlm.nih.gov/11359562/),
[PMID 16980493](https://pubmed.ncbi.nlm.nih.gov/16980493/),
[PMID 16923904](https://pubmed.ncbi.nlm.nih.gov/16923904/),
[PMID 22239271](https://pubmed.ncbi.nlm.nih.gov/22239271/);
review [PMID 17435791](https://pubmed.ncbi.nlm.nih.gov/17435791/)).

The eight-function proxy -- Flp `K02651`, prepilin peptidase `K02278`, CpaB/RcpC
`K02279`, secretin `K02280`, TadZ `K02282`, TadA `K02283`, TadB `K12510`, TadC
`K12511` -- is complete in 1,631 genomes; 1,284 of them do not complete the type
IVa pilus proxy, so the KOs separate the two machines. 316 are one short, spread
across Flp (67), peptidase (89), secretin (79) and TadZ (49). The Flp pilin is
therefore not the dominant gap: `K02651` is assigned in 3,186 genomes and
dropping pilin and peptidase raises the complete set only to 1,803.

Two limits. NCBIfam has one equivalog in the whole machine (`TIGR03177.1` CpaB);
the Flp pilin is a `domain`, TadZ a `PfamEq` and TadF a `subfamily`, so this is
a KO-only GIFT. And `K02283`, `K12510` and `K12511` are each in more than 4,000
genomes against 2,075 with the secretin: a secretin-free architecture for
monoderms is plausible but not defensible yet, because 597 of its 918 one-short
genomes lack the peptidase KO. Curate the diderm design only. Whether TadD,
RcpB and the TadE/F/G pseudopilins are required functions is left to the
curation pass.

### 6.3 Type II secretion system

Claim: the genome encodes a type II secretion apparatus. It excludes the
identity of any secreted substrate. Required inventory after
[PMID 22466878](https://pubmed.ncbi.nlm.nih.gov/22466878/): GspC, the GspD
secretin, the GspE ATPase, the GspF platform, the major pseudopilin GspG, the
minor pseudopilins GspH/I/J/K, GspL, GspM and a prepilin peptidase.

The homology with the type IVa pilus is resolved at marker level. Each T2SS
function has its own KO (`K02452`--`K02462`) and its own NCBIfam equivalog
(`TIGR01713.1`, `TIGR02517.1`, `TIGR02533.1`, `TIGR02120.1`, `TIGR01710.1`,
`TIGR01708.2`, `TIGR01707.1`, `TIGR01711.1`, `NF037980.1`, `TIGR01709.2`,
`NF040576.1`). The eleven-function proxy is complete in 1,571 genomes, of which
813 do not complete the type IVa pilus proxy and 758 complete both.

The exception is the peptidase. `K02464` GspO is assigned in 331 genomes and
`K02654` PilD in 4,102, with 51 carrying both: KEGG files the one prepilin
peptidase under PilD. That is one protein serving two machines, a shared
component and not an ambiguous marker, and it is exactly the case the
shared-homologue rule must settle. GspC is the weak component: it is the
missing function in 335 of 504 one-short genomes, and GspM in 93.

### 6.4 Gas vesicles

Deferred. Eight of fourteen *gvp* genes -- *gvpA*, *F*, *G*, *J*, *K*, *L*, *M*
and *O* -- are sufficient in halophilic archaea
([PMID 10894744](https://pubmed.ncbi.nlm.nih.gov/10894744/); review
[PMID 22941504](https://pubmed.ncbi.nlm.nih.gov/22941504/)). KEGG has a KO for
GvpA (`K23262`, 605 genomes) and GvpC (`K23263`, 11) and for none of the
assembly proteins. NCBIfam has equivalogs for GvpF, GvpL, GvpN, GvpQ and GvpU,
but GvpA, GvpG, GvpJ and GvpM are `exception` profiles and GvpK is a `domain`.
Five required proteins therefore have no admitted marker, and a GvpA-only GIFT
would be a single-gene checklist. Whether GvpA is routinely missed could not be
measured: the frame is KO-only and there is no second marker to compare with.

### 6.5 BAM complex

Refused as uninformative. BamA and BamD are the essential pair
([PMID 15851030](https://pubmed.ncbi.nlm.nih.gov/15851030/),
[PMID 16824102](https://pubmed.ncbi.nlm.nih.gov/16824102/)). `K07277` is in
6,073 bacteria and the pair in 5,262. Of 4,359 genomes carrying LptD `K04744`,
4,321 carry BamA. The call restates that the organism has an outer membrane,
which the Lpt GIFT and the envelope already say. The five-subunit complex is
complete in 2,101 genomes, all but six of them Gamma- or Betaproteobacteria or
Enterobacteria: BamB, BamC and BamE are lineage accessories, so requiring them
measures taxonomy. `K07277` also merges BamA with eukaryotic SAM50/TOB55 and
would need replacing by `TIGR03303.1`.

### 6.6 Curli

Curatable but narrow. CsgA, CsgB, CsgE, CsgF and CsgG are required
([PMID 11823641](https://pubmed.ncbi.nlm.nih.gov/11823641/),
[PMID 16704339](https://pubmed.ncbi.nlm.nih.gov/16704339/)); CsgC is accessory
and CsgD is a regulator outside the structure. All five have a KO and an
equivalog (`NF007470.1`, `NF007506.1`, `NF007701.0`, `NF007469.0`,
`NF011731.0`). The proxy is complete in 252 genomes, 250 of them
Enterobacteria. The secretion functions alone are complete in 591, including
276 other Gammaproteobacteria and 21 Bacteroidota, and 271 of 285 one-short
genomes miss CsgA. The major subunit is where the call fails outside
Enterobacteria, and widening its marker to the `curlin-type repeat` profile is
what invariant 16 forbids.

### 6.7 Chaperone-usher pili

The class is refused. `K07347` is defined as `fimD, fimC, mrkC, htrE, cssD` and
so cannot name a pilus; an usher plus a chaperone is present in 1,783 genomes,
and adding any major subunit KO drops that to 1,133, with the subunit missing in
650 of 671 one-short genomes. Named designs are rare: the type 1 inventory
FimA/C/D/F/G/H completes 179 genomes and the Pap inventory 11. Classification
follows [PMID 18063717](https://pubmed.ncbi.nlm.nih.gov/18063717/). NCBIfam's
usher and chaperone equivalogs are mostly unnamed or named for single
*Salmonella* operons and do not supply a subunit marker.

### 6.8 Type IV secretion and conjugation

The class is refused. Mating-pair formation divides into eight classes
([PMID 24623814](https://pubmed.ncbi.nlm.nih.gov/24623814/)); KEGG's KOs cover
the VirB/Trb, F and Dot/Icm designs and none of the monoderm, Bacteroidota or
cyanobacterial ones. The apparatus also does not say whether it conjugates DNA
or translocates effectors. Within the covered designs: VirB2--VirB11 with VirD4
([PMID 8206843](https://pubmed.ncbi.nlm.nih.gov/8206843/)) completes 91 genomes
and VirB7 is missing in 224 of 268 one-short genomes; without VirB2, VirB5 and
VirB7 it completes 602. The nine-function Trb proxy completes 643 with only 71
one short. The F-type proxy completes 75, losing TraA in 89 and TraD in 87; the
Dot/Icm proxy completes 33, losing DotA in 46. A Trb-type apparatus is the
cleanest narrowed candidate, but VirB and Trb are homologous designs carried by
separate KOs and only 44 genomes complete both, so it waits on the
shared-homologue rule.

### 6.9 Bacterial microcompartments

The class is refused and one design is recommended. Shell KOs are named `pdu`,
`eut` and `ccm`, but the hexamer, trimer and pentamer proteins are homologous
across loci ([PMID 25340524](https://pubmed.ncbi.nlm.nih.gov/25340524/),
[PMID 34155212](https://pubmed.ncbi.nlm.nih.gov/34155212/)), so a shell KO
cannot carry the substrate its name implies. Any hexamer with any pentamer
completes 518 genomes, and 438 of 441 one-short genomes miss the pentamer: the
vertex protein is the routinely missed subunit. The beta-carboxysome is the
exception. CcmK, CcmL, CcmM, CcmN and CcmO complete 160 genomes, all
Cyanobacteriota, with 9 one short, and NCBIfam has equivalogs for CcmL
(`NF053795.1`), CcmN (`NF053793.1`), CcmO (`NF053792.1`), CcmP and an
`equivalog_domain` for CcmM. The alpha-carboxysome has equivalogs for CsoS1,
CsoS2 and CsoS4 and no shell KO, so it is not measurable in this frame.

### Not verified in this screen

- That each KO's assignments are free of the homologue it is meant to exclude.
  Separate KOs and partial overlap are consistent with that and do not prove it.
  No protein was searched against an NCBIfam profile.
- The identity of the 190 archaea carrying FlaI or FlaJ without an archaellum
  core. Archaeal type IV pilus homologues is the assumed explanation.
  *Resolved for the archaellum by `GEA-20261003-ARCHAELLUM`; see §6.1.*
- Whether VirB and Trb KO assignments reflect a biological distinction.
- KO definitions against KEGG after 2026-08-22. *The archaellum orthologies
  and K02654 were re-checked on 2026-10-03 and are unchanged.*

## 7. Secretion machines reassessed 2026-10-03

Type III and type VI secretion were deferred twice, in
[the next-release assessment](proposal-next-gift-release.md) and again after
NCBIfam was admitted. The standing objection was that system identity requires
gene-cluster organisation: TXSScan and MacSyFinder discriminate homologous
secretion systems by combining profiles *with* locus structure, and gifter
receives an unordered set of accessions. The NCBIfam retrigger noted that this
argument had to be re-run rather than assumed, because a set of
system-specific components is not the same evidence as an unordered set of
homologous ones.

This pass ran it. The objection does not hold for these two architectures, and
both are curated in database 2026.31.1.

### What the objection confused

Two distinct claims were bundled into one refusal:

1. **These components form one machine.** Co-localisation is evidence for this,
   and gifter cannot see it.
2. **This accession identifies a component of this machine rather than of its
   homologue.** This is marker specificity, which is namespace evidence, not
   context.

Only the second is required by the completeness contract. gifter never claims
that the components of a curated architecture lie in one locus — no structural
GIFT does, including the flagellum, which has been curated from an unordered
marker set since the first structural release. What makes a role set a machine
is the curated architecture, not the genome's gene order. The first claim is a
*corroborating* axis, which
[the genomic-context assessment](proposal-genomic-context.md) recommends
keeping separate from the Boolean call, and refuses as marker-specificity
evidence.

So the question is only whether the accessions are specific. They are.

### Marker specificity against the homologue

The injectisome export apparatus is homologous to the flagellar one: SctR/S/T
to FliP/Q/R, SctU to FlhB, SctV to FlhA and SctN to FliI
([PMID 23028376](https://pubmed.ncbi.nlm.nih.gov/23028376/)). KEGG and NCBIfam
both separate the two families, and the separation holds in the frame:

- The three flagellated controls that encode neither secretion system —
  *Escherichia coli* K-12, *Bacillus subtilis* 168 and *Campylobacter jejuni* —
  support **no** role of either architecture.
- 4,399 frame genomes complete the seven-role flagellar export apparatus while
  supporting no injectisome role at all.
- Of 11,908 prokaryotic frame genomes, 10,801 support no injectisome role and
  9,563 no type VI role. Completeness is bimodal rather than graded: the
  injectisome reaches 344 complete genomes with 257 one role short, and the
  type VI apparatus 1,701 with 203 one short. Neither resembles an
  annotation-completeness proxy of the kind the peptidoglycan audit rejected.

The curated architectures therefore use injectisome-specific and type
VI-specific accessions only. No flagellar accession is accepted for the
injectisome and no injectisome accession for the flagellum; a test asserts both
directions.

### Two roles that markers cannot require

Invariant 16 bounds the claim by the evidence, and twice here the honest
consequence was to weaken the *architecture* rather than widen a marker.

**TssJ is accessory.** The outer-membrane lipoprotein completes the membrane
complex in many proteobacteria, but *Agrobacterium fabrum* and
*Acinetobacter baumannii* carry no TssJ marker in either namespace while their
apparatus is experimentally active — Acinetobacter Hcp secretion depends on
TssM ([PMID 23365692](https://pubmed.ncbi.nlm.nih.gov/23365692/)). Requiring
TssJ would report absent machinery in genomes that build it. It is recorded as
an accessory function, the same decision the type IVa pilus takes for PilT.

**The SctL stator is outside the required set.** SctL tethers the export ATPase
and is biologically required, but no accepted accession reaches the Inv-Mxi-Spa
and Esc families: `TIGR02499.1` is a Pseudomonadati-scoped equivalog,
`NF011850.0` is Salmonella OrgB and `NF005392.0` is an HrpE/YscL family
profile. Requiring the role would report an absent injectisome in *Shigella
flexneri* and enteropathogenic *Escherichia coli*, which plainly build one. The
role is excluded from the architecture and the reason is recorded on the export
ATPase function, so a later equivalog can promote it.

Both decisions are visible rather than silent: the architecture under-claims
two components it cannot evidence, instead of accepting a profile that would
also fire on something else.

### A KO accepted only after its proteins were tested

KEGG assigns some type VI proteins to orthologies named for the system rather
than the role — `K11905` and `K11910` are "type VI secretion system protein"
and VasJ. *Vibrio cholerae* TssA and TssE sit there, so rejecting them would
lose the model organism of the whole field.

Rather than accept them on their names, the screen searched the proteins KEGG
assigns to each accession against the role's equivalog, on a systematic sample
of at most 100 frame proteins:

| Accession | Role tested | Passing the role equivalog | Decision |
|---|---|---:|---|
| `K11910` VasJ | TssA | 95 of 100 | accepted |
| `K11902` ImpA | TssA | 73 of 100 | accepted |
| `K11905` | TssE | 96 of 100 | accepted |
| `K11919` HsiF3 | TssE | 75 of 75 | accepted |
| `K11897` ImpF | TssE | 89 of 100 | accepted |
| `K11906` VasD | TssJ | 99 of 100 | accepted |
| `K11918` lip3 | TssJ | **0 of 100** | **refused** |

`K11918` is a type VI accession whose proteins do not pass the TssJ profile at
all. It is refused as TssJ evidence, and a test asserts that it supports no
component. The full result is in
[`secretion-system-marker-audit.tsv`](../../data-raw/reference/secretion-system-marker-audit.tsv).

`K11892` TssL and `K11891` TssM also contain the IcmH/DotU and IcmF proteins of
the *Legionella* type IVB system. They are retained because neither is evidence
of anything on its own: both are required components inside a twelve-role
architecture, and the type IVB system supplies no other required role.

### The claims, and what they exclude

> **Type VI secretion apparatus.** The genome encodes the TssL/TssM membrane
> complex, the TssE/F/G/K baseplate, the VgrG spike, the Hcp tube, the TssB/TssC
> contractile sheath, the TssA coordinator and the ClpV recycling ATPase of one
> complete curated apparatus.

> **Type III secretion injectisome.** The genome encodes the SctR/S/T/U/V export
> apparatus, the SctN ATPase, the SctD/SctJ rings, the SctC secretin, the SctQ
> sorting platform, the SctI inner rod and either a needle filament or an Hrp
> pilus of one complete curated injectisome.

ClpV is required rather than accessory: sheath remodelling by ClpV is
experimentally crucial for secretion
([PMID 19131969](https://pubmed.ncbi.nlm.nih.gov/19131969/)), as the
sheath-and-tube mechanism predicts
([PMID 22367545](https://pubmed.ncbi.nlm.nih.gov/22367545/)). TssA is required
because it primes and coordinates tube and sheath polymerisation
([PMID 26909579](https://pubmed.ncbi.nlm.nih.gov/26909579/)). The injectisome
inventory follows the assembly literature
([PMID 24484471](https://pubmed.ncbi.nlm.nih.gov/24484471/)) and the in situ
structure, whose sorting platform makes SctQ a core role
([PMID 28283062](https://pubmed.ncbi.nlm.nih.gov/28283062/)).

Neither call means the machine is expressed, assembled or fired. Neither
identifies an effector, an immunity protein, a translocon, a host or a target.
Neither supports interbacterial antagonism, virulence, symbiosis or any other
phenotype — under invariant 18 those are higher-order descriptions to be derived
from typed GIFTs, never primary types. Effectors, immunity proteins, adaptors,
PAAR tip proteins, chaperones, gatekeepers, needle-length rulers, pilotins and
regulators are outside both claims.

### Deliberate under-calls

| Under-call | Why it is not curated |
|---|---|
| Francisella-type (T6SS-ii) and Bacteroidota-type (T6SS-iii) apparatuses | Divergent components. NCBIfam's Francisella profiles are Francisella-scoped exceptions and equivalogs for Igl proteins, which cannot license a general architecture; the Bacteroidota system ([PMID 25070807](https://pubmed.ncbi.nlm.nih.gov/25070807/)) has no admitted inventory. Each needs its own architecture with its own markers. |
| Chlamydial injectisome | *Chlamydia trachomatis* supports 10 of 12 required roles; SctI and the filament have only Chlamydia-scoped profiles. |
| Rhizobial and *Myxococcus* injectisome-like systems | 8–9 roles of 12, missing the secretin, rings or filament. |
| Ralstonia-type HrpY pilus | No accepted pilin marker; *R. pseudosolanacearum* GMI1000 therefore stops one role short. |
| A TssJ-requiring or SctL-requiring architecture | Blocked on the markers above, not on the biology. |

These are absences of evidence, not biological negatives, and each has a
deferral-register row.

### Prevalence and controls

Full results are in
[`secretion-system-prevalence.tsv`](../../data-raw/reference/secretion-system-prevalence.tsv),
[`secretion-system-roles.tsv`](../../data-raw/reference/secretion-system-roles.tsv) and
[`secretion-system-controls.tsv`](../../data-raw/reference/secretion-system-controls.tsv),
regenerated by `data-raw/secretion_system_prevalence.R`. Seventeen named
reference strains were checked against what they are established to carry: 17
of 19 expected machines complete, and nothing completes where no machine is
expected. The two misses are the chlamydial injectisome and the Ralstonia Hrp
pilus, both under-calls listed above. No taxon, neighbourhood or absence
pattern was used to rescue a call.

## 8. Type II secretion system, curated 2026-10-03

The T2SS was the one candidate from the machine screen (§6.3) that was blocked
on something other than evidence. Its class III prepilin peptidase is not a
*homologue* of the type IVa pilus peptidase; it is the same enzyme, and KEGG
files most of them under PilD rather than GspO
([PMID 1309616](https://pubmed.ncbi.nlm.nih.gov/1309616/)). Curating the
apparatus therefore required a decision about what it means for two GIFTs to
share a component. That decision is now taken, as
[open question 1](#4-open-questions) and in
[the architecture guide](architecture.md#shared-components-and-the-ambiguity-that-is-not-a-marker-defect):
a shared component is accepted on both GIFTs, contributes no specificity to
either, and does not make the two GIFTs compose.

The quantities confirm that this was the right thing to settle first rather than
work around. **1,319 of the 1,536 complete architectures in the frame reach the
peptidase role through PilD alone.** Refusing the shared accession would have
discarded six sevenths of the capability; accepting GspO only would have made the
GIFT a Pseudomonadota-flavoured curiosity.

### The claim

> The genome encodes one complete curated type II secretion apparatus: the GspD
> outer-membrane secretin, the GspC/F/L/M inner-membrane platform, the GspE
> secretion ATPase, the GspG/H/I/J/K pseudopilus, and the class III peptidase
> that matures the pseudopilins.

The architecture follows the four real subassemblies plus maturation
([PMID 22466878](https://pubmed.ncbi.nlm.nih.gov/22466878/)) rather than one
function per protein, the same choice the injectisome export apparatus makes.
The minor pseudopilins are jointly required with GspG because their tip complex
primes elongation of the pseudopilus
([PMID 22157749](https://pubmed.ncbi.nlm.nih.gov/22157749/)), and the platform
proteins are jointly required as the secreton interactions describe
([PMID 10735856](https://pubmed.ncbi.nlm.nih.gov/10735856/)).

A positive call does not identify the secreted substrate — that is the whole
point of a machine that exports whatever is delivered to it — and says nothing
about expression, assembly, secretion, polymer degradation, host colonisation or
virulence. The GspS pilotin, GspN and GspAB are outside the claim.

### Specificity against the pilus it shares an enzyme with

| Measure | Genomes |
|---|---:|
| Complete Gsp inventory | 1,571 |
| Complete architecture, peptidase included | 1,536 |
| Cost of requiring the peptidase | 35 |
| Complete T2SS **without** a complete type IVa pilus | 703 |
| Complete type IVa pilus **without** a complete T2SS | 674 |
| Complete both | 833 |

That the peptidase costs only 35 genomes is the shared-component rule showing up
as a number: a role both machines satisfy with the same protein does almost no
discriminating work. The discrimination is done by the other four functions, and
it is substantial — the two machines are each complete in several hundred genomes
where the other is not. The architecture is complete across 319 genera, so it is
a broad capability rather than a lineage claim.

### GspC stays required, and the reason is not comfort

GspC is the weakest marker in the inventory: it is the missing function in 335 of
the 504 genomes that are exactly one function short, and it is why
*Legionella pneumophila* Philadelphia 1 is under-called despite its established
Lsp system.

Making it accessory would be the easy repair and it is refused. The architecture
guide reserves `required = 0` for cases where the biology says a machine works
without a part, not where evidence is inconvenient, and GspC is the linker that
connects the platform to the secretin. The distinction from the injectisome's
SctL stator, which *was* excluded in §7, is where the misses fall: no accepted
SctL accession reaches the Inv-Mxi-Spa or Esc families at all, so requiring it
would blind the GIFT to whole clades, whereas GspC's 335 misses are spread over
108 genera with no genus above 9.3%. One is a systematic hole, the other is
scattered sequence divergence. The first changes the architecture; the second is
an honest under-call with a deferral row.

### A control miss that is the model working

*Vibrio cholerae* N16961 is the textbook T2SS — its Eps apparatus secretes
cholera toxin — and gifter calls it **incomplete**, missing the secretin.

This is correct. KEGG assigns no GspD orthology to that genome because
`VC_2733`, which sits exactly where *epsD* belongs between `epsC` (`VC_2734`) and
`epsE` (`VC_2732`), carries an authentic frameshift; KEGG's own record states
that it "contains an authentic frame shift and is not the result of a sequencing
artifact", and the gene has no KO. Searching the whole proteome with the GspD
equivalog finds only the type IV pilus secretin and MshL, both far below the
gathering threshold. The genome does not encode an intact secretin, and the
discrete model reports that rather than scoring the apparatus 11/12 and calling
it present. A percentage would have hidden exactly the thing worth seeing.

### Controls

Twelve named strains, compared with what each is established to encode and never
the other way round:

| Expectation | Result |
|---|---|
| T2SS established (5) | *P. aeruginosa*, *E. coli* K-12, *X. campestris*, *A. hydrophila*, *D. chrysanthemi* complete |
| T2SS established (2) | *V. cholerae* incomplete on a frameshifted secretin; *L. pneumophila* incomplete on GspC |
| No T2SS (3) | *B. subtilis*, *C. jejuni*, *H. pylori* all incomplete; *C. jejuni* carries 2 of 11 roles |
| Not checked (2) | *E. coli* O157:H7 and *K. michiganensis* complete; recorded as `unverified` |

Full results are in
[`t2ss-prevalence.tsv`](../../data-raw/reference/t2ss-prevalence.tsv),
[`t2ss-roles.tsv`](../../data-raw/reference/t2ss-roles.tsv) and
[`t2ss-controls.tsv`](../../data-raw/reference/t2ss-controls.tsv), regenerated by
`data-raw/t2ss_prevalence.R`.
