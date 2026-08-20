# Curation proposal: next coherent GIFT release

Status: **assessed 2026-08-20; metabolic subset accepted and implemented as
database version 2026.20.1 (schema 6).**

This assessment considered nitrogen fixation, assimilatory sulfate reduction,
the glyoxylate bypass, a type III or type VI secretion system, an OxyR/PerR
peroxide response, a defense expansion and additional complex-glycan
degradation. It applies the same rule to every type: a positive call may state
only the complete encoded capability supported by the evidence, never activity,
physiological state, ecological effect or phenotype.

## 1. Decision summary

| Candidate | Type and boundary/model | Decision | Decisive reason |
|---|---|---|---|
| Nitrogen fixation | metabolic; `NITROGEN` to `AMMONIUM` | implement | Complete Mo and V nitrogenase architectures and their chemistry are specifically markable. NifH alone is not. |
| Assimilatory sulfate reduction | metabolic; `SULFATE` to `SULFIDE` | implement | APS/PAPS and terminal-reductase alternatives can be materialised as four complete routes while excluding respiratory systems. |
| Glyoxylate bypass | metabolic; `ISOCITRATE` + `ACETYL_COA` to `SUCCINATE` + `MALATE` | implement with an upper-TCA re-cut | Isocitrate is the branchpoint that avoids duplicating citrate synthase and aconitase. |
| Type III/type VI secretion | structural machinery model | defer | System identity depends on several homologous components being co-localised in one architecture; an unordered marker set cannot establish that. |
| OxyR/PerR peroxide response | regulatory circuit model | defer | Regulator orthology can identify a sensor family but not its cognate response targets or a complete lineage-specific regulon. |
| Defense expansion | defense machinery model | no new GIFT | Type I-E CRISPR-Cas protein machinery is already curated. Another subtype would repeat the unresolved array/context limitation. |
| Complex glycans | metabolic route model | defer | Broad CAZy families do not resolve substrate identity, and PUL/CGC context is not represented by the current evidence input. |

The coherent release is therefore metabolic. It adds four net GIFTs: two new
capabilities, one bypass, and one extra atomic segment created by replacing one
bundled TCA GIFT with two. No new `gift_type`, schema table, runtime conditional
or context model is introduced.

## 2. Nitrogen fixation

### Claim and boundaries

`nitrogen_fixation` is `metabolic`, `anabolic`, from dinitrogen
(`CHEBI:17997`) to ammonium (`CHEBI:28938`). A positive call means that one
complete curated nitrogenase and its indispensable nitrogenase-specific
cofactor-assembly machinery are encoded. It does not mean the genes are
expressed, the oxygen-sensitive complex is protected, reductant is available,
or nitrogen is fixed in the sampled environment.

Rhea release 141 supplies two masters: `RHEA:21448` for the Mo enzyme and
`RHEA:55543` for the V enzyme. They are alternative routes of the same boundary
capability, not alternative systems of one reaction, because their coupled
stoichiometries differ.

### Architectures and Boolean placement

The Mo system requires all six components:

```text
NifH + NifD + NifK + NifB + NifE + NifN
K02588 K02586 K02591 K02585 K02587 K02592
```

NifHDK are the electron-delivery and catalytic components. NifB forms the
cofactor precursor and NifEN is the specific maturation scaffold. Specialist
reviews and minimum-gene surveys converge on `nifHDKENB` as the irreducible
genome-level signature. NifU/NifS Fe-S supply can be substituted by host Isc/Suf
machinery; NifV and NifM are not universally part of the minimum signature, so
they are not required.

The V system separately requires:

```text
VnfH + VnfD + VnfK + VnfG + NifB + VnfE + VnfN
K22899 K22896 K22897 K22898 K02585 K22903 K02592
```

The delta subunit is a required part of the V catalytic architecture, and VnfEN
is the V-specific cofactor scaffold. `K02592` is retained for VnfN because KEGG
uses that group for validated `vnfN` genes as well as naming the entry NifN.

### Refusals and deferrals

- NifH alone is refused. It is one required component and homologous proteins
  occur outside complete nitrogen-fixing architectures.
- `K00531` (AnfG) alone is refused for the same reason.
- The Fe-only route is deferred. Its delta subunit is separately markable, but
  current KO groups do not cleanly separate AnfHDK from NifHDK, and experimental
  minimum constructs and native systems differ over VnfEN, NifU/S/V and host
  substitutions. Encoding one disputed list as complete would turn uncertainty
  into false precision.

Primary and specialist evidence consulted: Dos Santos et al., *BMC Genomics*
2012 (minimum `nifHDKENB` survey); Yang et al., *PNAS* 2014 (experimental
Fe-only reconstruction); Jasniewski et al., *mBio* 2021 (NifEN/VnfEN
specificity); and the current KEGG M00175 definition, checked 2026-08-20.

## 3. Assimilatory sulfate reduction

### Claim and route materialisation

`assimilatory_sulfate_reduction` is `metabolic`, `anabolic`, from sulfate
(`CHEBI:16189`) to hydrogen sulfide (`CHEBI:29919`). It claims the encoded
assimilatory chemistry only. Uptake, sulfur incorporation, growth and sulfur
respiration are excluded.

Four valid minimal routes are materialised rather than parsed from an
expression:

| Route | Activation/reduction sequence |
|---|---|
| APS–NADPH | `RHEA:18136` forward, `RHEA:21976` reverse, `RHEA:13804` reverse |
| APS–ferredoxin | `RHEA:18136` forward, `RHEA:21976` reverse, `RHEA:23132` reverse |
| PAPS–NADPH | `RHEA:18136`, `RHEA:24152` forward, `RHEA:11724`, `RHEA:13804` reverse |
| PAPS–ferredoxin | `RHEA:18136`, `RHEA:24152` forward, `RHEA:11724`, `RHEA:23132` reverse |

At the enzyme-system layer, sulfate adenylyltransferase is satisfied by Met3/Sat
(`K00958`), CysN+CysD (`K00956`+`K00957`), or CysNC+CysD
(`K00955`+`K00957`). APS kinase is CysC (`K00860`) or the kinase domain of
CysNC (`K00955`). NADPH sulfite reductase requires both CysJ and CysI
(`K00380`+`K00381`); ferredoxin sulfite reductase is Sir (`K00392`).

### Specificity decision

KEGG currently assigns CysH `K00390` both EC 1.8.4.8 (PAPS reductase) and EC
1.8.4.10 (APS reductase), even though M00176 draws only the PAPS route.
Accepting the KO for both reaction components would let one observation satisfy
either branch and would erase the need for APS kinase. The release therefore
uses the reaction-specific EC accessions `1.8.4.8` and `1.8.4.10`. A caller
without activity-level annotation reports the branch reaction missing; it does
not guess.

Dissimilatory AprAB and DsrAB are explicitly refused. They support respiratory
sulfur transformations, not this anabolic boundary claim. The direct
assimilatory APS route is supported by Bick et al., *Applied and Environmental
Microbiology* 2000, which demonstrated a distinct bacterial class of
assimilatory APS reductases.

## 4. Glyoxylate bypass and the isocitrate re-cut

The detailed implementation record is in
[`proposal-central-metabolic-cycles.md`](proposal-central-metabolic-cycles.md#19-phase-3-implementation-isocitrate-and-the-glyoxylate-bypass-2026-08-20).
The important invariant is that one reaction belongs to one atomic claim:

- `acetyl_coa_to_isocitrate`: `RHEA:16845` + `RHEA:10336`;
- `isocitrate_to_oxoglutarate`: `RHEA:19629` or `RHEA:23632`;
- `glyoxylate_bypass`: `RHEA:13245` + `RHEA:18181`.

`K01637` and `K01638` are required for the direct bypass. `K01639` is refused
because it is N-acetylneuraminate lyase. `K19282`, which KEGG M00012 accepts as
an alternative, is deferred because it implements a two-reaction malyl-CoA
route rather than the direct malate-synthase master.

## 5. Deferred non-metabolic candidates

### Type III/type VI secretion

A secretion machine fits `structural`, not metabolic. The candidate is useful
and the existing `secretion_machine` facet is ready, but TXSScan/MacSyFinder
models discriminate homologous secretion and contractile systems by combining
multiple HMM profiles with gene-cluster organisation. gifter currently receives
an unordered set of namespaced accessions; it cannot say that the components
belong to one locus, or that orphan homologues assemble one machine. The trigger
for reconsideration is a general context evidence layer with a tested locus
contract, not a T6SS-specific R conditional.

### OxyR/PerR peroxide response

OxyR and PerR are alternative peroxide-responsive regulator families, but they
are not interchangeable marker implementations of one conserved circuit.
Their regulons vary by lineage; PerR additionally overlaps metal homeostasis,
and OxyR target sequences are poorly conserved. Regulator orthology can state
that a sensor-family protein is encoded but cannot establish the cognate
response arm required by the regulatory completeness model. Reconsider only
when target/regulon context is supported by a general evidence model or when a
lineage-bounded circuit with specific paired markers is curated.

### Defense expansion

`type_i_e_crispr_cas_machinery` already covers the proposed well-validated
CRISPR example as an encoded-protein claim. A second subtype is not added merely
to grow the catalogue: subtype identity and interference require the complete
subtype architecture, and functional interference additionally requires a
CRISPR repeat-spacer array that protein markers cannot evidence. The trigger is
the same genomic-feature/context extension already recorded in
[`proposal-defense-gifts.md`](proposal-defense-gifts.md).

### Complex glycans

No additional glycan candidate clears invariant 16. Families such as GH5 span
multiple substrates, so a family hit cannot distinguish cellulose from mannan;
accepting it for either would damage the other trait as well. dbCAN substrate
prediction increasingly relies on subfamily voting and CAZyme gene-cluster/PUL
context, but the two approaches agreed for only a minority of substrate-labelled
clusters in the 2023 dbCAN-seq update. Reconsider a named glycan only when a
substrate-resolving family/subfamily marker or a general PUL-context evidence
model supplies every required reaction without converting family breadth into
substrate specificity.

## 6. Implementation and verification record

Release 2026.20.1 changes biological source TSVs and regenerates SQLite; it
does not change schema version 6 or package code. It contains 134 GIFTs: 126
metabolic, two structural, three regulatory and three defense. Three anchors
and ten reactions are added relative to 2026.19.1. Ten route rows are added
while two old bundled TCA route rows are removed, for eight net new routes;
the old bundle is re-cut rather than duplicated.

The durable negative tests are: NifH alone and every incomplete nitrogenase
architecture remain negative; `K00390`, a one-subunit CysJI system and
dissimilatory sulfur markers remain negative for sulfate assimilation; and
`K01639` remains negative for the glyoxylate bypass. Composition tests require
the ammonium-to-assimilation and sulfide-to-amino-acid edges, the unique malate
edge, and the absence of an edge through internal sulfite or glyoxylate.
