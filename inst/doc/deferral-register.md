# Deferral register

Every curation proposal in this directory records refusals as well as
adoptions, because a refusal with its evidence is a result. Eight documents now
hold them, and nothing re-read those refusals when the evidence changed. This
register is the index that makes them re-readable: one row per standing
decision, with **what blocks it** and **what would unblock it**.

Seeded 2026-08-22 from the proposals listed below. It is a curation aid, not
database content — the database states what gifter claims, and a claim gifter
declined to make has no row in it.

**Rule for curators: a proposal that defers or refuses a candidate adds a row
here in the same change.** A deferral nobody can find again is not a decision,
it is a forgotten investigation.

Retriggers are grouped by what would have to change, because that is what makes
the register usable: when a namespace is admitted, read section 1; when the
genome frame moves, read section 2; when an architectural axis opens, read
section 3. Section 4 is closed and stays closed.

---

## 1. Blocked on marker specificity or marker existence

Retrigger: a new marker namespace, a finer grade within an existing one, or a
release of KEGG, Rhea, dbCAN or NCBIfam that adds an accession at the required
resolution. These are the rows to re-read after
[the specificity screen](proposal-marker-specificity-screen.md) or
[the NCBIfam assessment](proposal-ncbifam-namespace.md) is re-run.

| Candidate | Blocked because | Unblocks when | Source |
|---|---|---|---|
| ~~`siroheme_to_heme_b`, the Ahb route~~ | ~~`K22225` matches both AhbA and AhbB~~ | **Closed by curation in database 2026.24.1.** `NCBIFAM` was admitted in 2026.23.1, `NF040708.3` *ahbA* and `NF040707.3` *ahbB* separate the subunits, and the whole route was verified before curating. `K22225` is still admitted nowhere | [MetaCyc](proposal-metacyc-expansion.md), [NCBIfam](proposal-ncbifam-namespace.md) §8 |
| The fused NirDL-like siroheme decarboxylase, `NF046668.3` | Some organisms carry AhbA and AhbB as one polypeptide, and a fusion-specific marker was one of the three things named as unblocking the Ahb refusal. NCBIfam has a profile and it is `domain`-graded, so it carries no one-function guarantee and rule 1 refuses it | An equivalog-grade profile for the fused enzyme, in NCBIfam or another admitted namespace. Until then `siroheme_to_heme_b` under-calls the fused lineages | [NCBIfam](proposal-ncbifam-namespace.md) §8.2 |
| `K25033`, the second orthology group for peroxide-dependent heme synthase | Not blocked on evidence. KEGG splits the same activity across `K00435` and `K25033` with identical names and EC 1.3.98.5; gifter curates only `K00435`, so a genome annotated `K25033` alone fails both the coproporphyrin route and the Ahb route's alternative terminal step | Someone decides to add it. It is a `broadens` change to `heme_b_biosynthesis`, so it needs its own release rather than riding along with a route curation | [NCBIfam](proposal-ncbifam-namespace.md) §8.2 |
| Flagellar coupling ion, H⁺ versus Na⁺ | `K02556`/`K02557` cover both MotA/MotB and PomA/PomB | A profile or ortholog separates the sodium-driven stator. NCBIfam does not | [structural](proposal-structural-gifts.md) |
| Chemotaxis toward a named chemoeffector | A generic MCP accession cannot name a ligand | Per-receptor evidence. **The namespace is now available**: `NCBIFAM` was admitted in 2026.23.1, and `NF011622.0` *tar* and `NF011615.0` *tsr* are separate equivalogs, so nothing but curation blocks tightening `aspartate_chemoreception`. It still creates no new capability | [regulatory](proposal-regulatory-gifts.md) |
| CRISPR subtype identity | A generic Cas protein cannot license a subtype, and an array is not in the evidence layer | Subtype-specific component evidence, plus a decision on array detection | [defense](proposal-defense-gifts.md) |
| Aminoglycoside modification | No marker resolves the drug class; the resolvable level is one drug | A claim named for the chemistry rather than the drug class would not need this | [antimicrobial](proposal-antimicrobial-detoxification.md) §8 |
| ~~Macrolide esterase `ereA`~~ | ~~No KO exists~~ | **Refused, and the NCBIfam retrigger is closed.** Checked against `hmm_PGAP/20.0`: `NF000208.1` *ere(A)* and `NF000209.1` *ere(B)* are `exception`-graded, and the macrolide esterases that pass the grade filter act on 16-membered rings — `NF041759.1` *estT* states that it does **not** hydrolyse erythromycin. Nothing in the namespace evidences a trait named for this gene or this drug | [antimicrobial](proposal-antimicrobial-detoxification.md), [discovery](proposal-ncbifam-discovery.md) §3.1 |
| Macrolide ester hydrolysis, named for the chemistry rather than for a drug | Not blocked on evidence. `NF052610.1` *mle* is equivalog with 2,255 RefSeq hits and covers the alpha/beta-fold macrolide esterases as one family | Someone decides the broader claim is worth making. It belongs beside the detoxification GIFTs in the antimicrobial proposal, which are not curated, so it is not a claim gifter can currently place anywhere | [discovery](proposal-ncbifam-discovery.md) §3.1 |
| Caffeine N-demethylation | The required reductase has no KO. **NCBIfam checked and does not cover it**: release 20.0 holds no profile at any grade for NdmA–D or for the alternative *cdhABC* route | An accession for the *ndm* reductase in some admitted namespace. The NCBIfam retrigger is closed; the availability refusal stands | [aromatic](proposal-aromatic-degradation.md) §9.3, [discovery](proposal-ncbifam-discovery.md) §3.2 |
| Polyhydroxybutyrate biosynthesis | `K03821` names PHA synthases across substrate classes and cannot identify PHB. **NCBIfam checked and does not help**: every PhaC profile is `subfamily`- or `domain`-graded, and its classes separate polyester chain length rather than monomer, so re-grading them would not answer the question either | Monomer-resolving evidence — a marker whose members are known to accept (R)-3-hydroxybutyryl-CoA. The NCBIfam retrigger is closed. The refusal must not be bypassed by pairing a class marker with `NF042967.1` *phaA* and `NF042966.1` *phaB*, which are equivalog and supply the monomer without saying the polymerase takes it | [compatible solutes](proposal-compatible-solutes-heme-enterobactin-detoxification.md) §8, [discovery](proposal-ncbifam-discovery.md) §3.3 |
| The Fe-only nitrogenase architecture, AnfHDK | Recorded until now only in the `notes` column of `nitrogen_fixation` in `gifts.tsv`, which is the failure mode this register exists to prevent. That note says "current KO groups do not separate AnfHDK from NifHDK" and **it is now half false**: `TIGR01861.1` *anfD*, `TIGR02931.1` *anfK* and `TIGR02929.1` *anfG* are equivalogs and KEGG has no *anfD* or *anfK* at all. What still blocks it is the electron-delivery component and the reaction — `TIGR01287.1` *nifH* states that it includes *nifH*, *vnfH* and *anfH* together, so admitting it would let the molybdenum iron protein satisfy the Fe-only architecture, and Rhea has no master for the Fe-only stoichiometry, which evolves more hydrogen than `RHEA:21448` | An AnfH-specific profile, plus a Rhea master or a defensible cross-reference for the Fe-only reaction. The vanadium route needed its own Rhea entry for the same reason, curated as `RHEA:55543` — see the bidirectional-identifier row below. The `gifts.tsv` note should be re-stated when the source tables are next touched | [discovery](proposal-ncbifam-discovery.md) §4.4, `gifts.tsv` |
| The split iron–sulfur L-serine ammonia-lyase, SdaAA + SdaAB | Not blocked on evidence. `serine_deamination` evidences `RHEA:19169` with one component carrying `K01752` and `K17989`, both single-chain forms; `TIGR00718.1` *sdaAA* and `TIGR00719.1` *sdaAB* are equivalogs for the two chains of the split form, at 15,278 and 12,514 RefSeq hits, and their comments state the deep split from the single-chain lineage | Someone decides to add it. It is a second enzyme system on an existing reaction with two jointly required components, needs no new anchor, and is a `broadens` change to `serine_deamination`, so it needs its own release rather than riding along with a screen pass. Settle first whether `K01752` is assigned to the split halves in annotated genomes: if it is, a second and narrowing decision is owed, because the alpha chain alone completes the GIFT today | [discovery](proposal-ncbifam-discovery.md) §4.5 |
| The Stickland reductases on glycine, sarcosine and betaine | Not blocked on evidence, and **not an NCBIfam retrigger** despite being found by the NCBIfam discovery join. KEGG resolves all three substrate-determining B subunits (`K10671`/`K10672`, `K21583`/`K21584`, `K21578`/`K21579`) and NCBIfam resolves only glycine, because `NF040793.1`, `NF040794.1` and `NF040795.1` are `exception`-graded. The shared components `grdA`, `grdC` and `grdD` cannot name a substrate and NCBIfam says so: "A different subunit, B, determines the substrate" | Someone decides to curate it. Rhea covers all three (`RHEA:12232`, `RHEA:12825`, `RHEA:11848`), every anchor exists, and `proline_reduction_stickland` is the curated sibling. `discovery-candidates.tsv` from the KO screen already listed four of these accessions and nobody acted on it | [discovery](proposal-ncbifam-discovery.md) §5.3 |
| Hydroxyectoine utilization, `NF005680.0` *eutB* | Three reasons, none of them grade: the profile carries no EC and reaches no Rhea master, so invariant 4 would need a cross-reference nobody has read; its function assignment is unread and its empty `comment` gives nothing to read; and hydroxyectoine to ectoine is one step handing straight to the existing `ectoine_degradation`, which is the arbitrary single-step fragment invariant 9 refuses | A reaction with a Rhea master or a defensible cross-reference, plus a reason the single step is a capability rather than a fragment. `HYDROXYECTOINE` being an output-only anchor is the same shape as the chitosan deferral | [discovery](proposal-ncbifam-discovery.md) §5.3, [anchor fates](proposal-anchor-fates.md) §5.2 |
| Ectoine utilization `eutABC` | **Refused, not deferred.** `TIGR02990.1` *eutA* describes a *predicted* arylmalonate decarboxylase and adds that the family is missing from two species that carry the rest of the ectoine utilization genes — a family absent from organisms performing the capability cannot be a required component of it. `TIGR02992.1` is labelled *eutC* and its comment describes EutA, so the model's statement of what it recognises contradicts its own label | Nothing about a future release fixes a predicted function or a copied description. It becomes a candidate only if the chemistry is characterised and the models corrected | [discovery](proposal-ncbifam-discovery.md) §5.3 |
| NCBIfam's antimicrobial-resistance layer, as a whole | The `exception` grade. 1,392 profiles in release 20.0 carry it and 668 of those are AMRFinder models, so almost all of NCBIfam's resistance content sits outside gifter's admission rule. An `exception` model recognises a named resistance allele; it does not assert that a family shares one function, which is what the equivalog grade asserts and what invariant 16 needs | Only an explicit architectural decision to widen the grade filter, with its own release. Wanting a particular trait is not that decision. 45 `exception` profiles already reach a curated reaction and are listed in `ncbifam-grade-refusals.tsv`, where a test asserts none is ever a marker | [discovery](proposal-ncbifam-discovery.md) §6.1, [NCBIfam](proposal-ncbifam-namespace.md) §5 |
| Three curated reactions keyed by a bidirectional Rhea ID rather than a master | Not a capability: an identifier repair with a measurable cost. `RHEA:55543`, `RHEA:18136` and `RHEA:13804` are the bidirectional forms of masters `RHEA:55540`, `RHEA:18133` and `RHEA:13801`. Invariant 4 identifies a reaction by its master and stores direction in the route, so a bidirectional child states direction twice. **Both specificity screens key on masters, so these three reactions are silently outside every measurement either screen makes** — not reported broad, narrow or unscreened, simply absent | A release that edits `reactions.tsv` and moves the foreign keys. Affects `nitrogen_fixation` and `assimilatory_sulfate_reduction` | [discovery](proposal-ncbifam-discovery.md) §4.6 |
| The rationale for `KO:K14048` on the urease beta and gamma components | Not a capability: a curation-hygiene repair. `K14048` is the only accession in the whole catalogue shared across two components of one system, and it is correct — KEGG's *ureAB* is the genuine gamma–beta fusion, so one gene does satisfy both. Both `component_markers.tsv` rows record an empty `notes`, so a reader auditing for exactly this failure mode finds the shape of a defect with no argument beside it | The next release that touches the source tables writes the fusion rationale into both rows | [discovery](proposal-ncbifam-discovery.md) §4.2 |
| Nine aromatic capabilities — toluene, benzene, xylene, cumate, *p*-cymene, biphenyl, carbazole, naphthalene, terephthalate | Ring-hydroxylating dioxygenase families cannot say which ring they hydroxylate | Not by a finer family: the enzymes are promiscuous as proteins. Only substrate-resolving evidence of a kind gifter does not have | [aromatic](proposal-aromatic-degradation.md) |
| Elastin, keratin, albumin, actin, glutelin, tropomyosin, troponin cleavage | EC 3.4.24.26 hydrolyses several of these; for most, no orthologue exists at all | Substrate-resolving peptidase evidence. MEROPS is the resource to assess | [protein degradation](proposal-protein-degradation.md) |
| Tryptophan to tryptamine, as named | Aromatic amino acid decarboxylase evidence does not single out the substrate | Substrate-resolving decarboxylase evidence | [amino acid metabolism](proposal-amino-acid-metabolism.md) §12.2 |
| Complex glycan degradation beyond the curated set | Broad CAZy families do not resolve substrate identity | dbCAN subfamily coverage at the required specificity, or PUL context — which is section 3 | [next release](proposal-next-gift-release.md) |
| SusC/SusD substrate assignment | The pair is a transport machine, not a substrate claim | Never from context alone; explicitly refused, not deferred | [polysaccharide](proposal-polysaccharide-degradation.md) §4.6 |
| Pantothenate to coenzyme A, riboflavin to FAD, TMP to TPP, folate to polyglutamate | Not a marker problem: cofactor activation is complete in essentially every genome, so the trait partitions nothing and carries annotation noise | Never on evidence. Only if a reason appears to read a step that is universal | [vitamins](proposal-vitamin-biosynthesis.md) §8.2 |
| Biotin precursor supply, malonyl-ACP to pimeloyl-ACP, and BioW from free pimelate | BioC/BioH is one of at least four non-homologous solutions; curating one would answer the question only for that lineage. BioW additionally needs `PIMELATE` as a source anchor nothing else touches | The other routes reach the same standard, or the claim is renamed for the specific chemistry rather than for precursor supply | [vitamins](proposal-vitamin-biosynthesis.md) §6.7, [anchor fates](proposal-anchor-fates.md) §5.1 |
| DoeD and DoeC, the last two steps of ectoine catabolism | Their reaction `RHEA:11160` is shared with `ectoine_biosynthesis`, and `K15785` was refused as an EctB alternative. Enzyme systems attach to reactions, not routes, so admitting DoeD anywhere admits it there | Route-scoped enzyme systems, which is a schema change. Guarded by a test in `test-compatible-solutes-heme-enterobactin-detoxification.R` | [anchor fates](proposal-anchor-fates.md) §3 |
| Chitin deacetylation to chitosan | Curatable and specific, but chitosan would be an output-only anchor with no curated chemistry on the other side | A chitosan-consuming capability is curated | [anchor fates](proposal-anchor-fates.md) §5.2 |
| Allantoin racemisation | Would need an `ALLANTOIN_R` anchor whose only purpose is to be the other side of a racemase | Someone reads the (R) form as a boundary. `lactate_racemisation` is the precedent for admitting one | [anchor fates](proposal-anchor-fates.md) §5.2 |
| The oxidative rhamnose route, LRA1 to LRA4 | Not deferred on evidence. It is an alternative route of the existing `rhamnose_degradation` rather than a GIFT, and the upstream three steps have not been checked | The LRA1 to LRA3 reactions and markers are verified | [anchor fates](proposal-anchor-fates.md) §5.2 |
| Variant- and SNP-based resistance | Resistance is a residue and the evidence layer has no accession for a residue | An evidence model with residue-level identity, which is not on the roadmap | [antimicrobial](proposal-antimicrobial-detoxification.md) §9.4 |
| Oxepin-CoA hydrolase, the alternative-type protein `NF046063.1` | It passed the equivalog filter and was refused twice over: NCBIfam names it an "alternative type", so attaching it to the PaaZ hydrolase-domain component would assert a homology the profile denies, and its function was assigned from TnSeq fitness data rather than characterised | Its chemistry is read well enough to curate a second enzyme system on `RHEA:31755`, at which point the profile is `putative` evidence for that system rather than for PaaZ | [NCBIfam](proposal-ncbifam-namespace.md) §7.1 |
| Migrating the five unversioned `TIGRFAM` rows into `NCBIFAM` | They are JCVI profiles maintained inside NCBIfam, recorded from InterPro without a version suffix. Re-namespacing them would silently stop matching for users whose annotation emits the unversioned form, and there is no marker-alias model that could hold both | A marker-alias or accession-equivalence model, or a deliberate release that accepts the break and re-derives the five rows against a pinned NCBIfam release | [NCBIfam](proposal-ncbifam-namespace.md), `SOURCES.md` |

## 2. Blocked on prevalence

Retrigger: a change to the reference genome frame, or an explicit decision to
curate a capability that is rare but biologically decisive. The 20–50 genome
band is the standing test; below it a candidate is not refused on biology.

| Candidate | Prevalence at assessment | Source |
|---|---|---|
| `tetX` tetracycline 11a-monooxygenation | 34 genomes, inside the band | [antimicrobial](proposal-antimicrobial-detoxification.md) §8 |
| Lysine to butyrate and acetate | 266 genomes, 2.6% | [amino acid metabolism](proposal-amino-acid-metabolism.md) §12.6 |
| Anaerobic toluene activation, `bssA` | 10 genomes; the marker is specific, the prevalence is not | [aromatic](proposal-aromatic-degradation.md) |
| Benzoyl-CoA, cyclohexanecarboxylate, salicylate to gentisate, phthalate 4,5 | 23–83 genomes; marker-passing, prevalence-marginal | [aromatic](proposal-aromatic-degradation.md) |
| Tyrosine to tyramine | 0 genomes | [amino acid metabolism](proposal-amino-acid-metabolism.md) §12.1 |

## 3. Blocked on an architectural axis gifter does not have

Retrigger: a decision on the axis itself. Each of these is a well-understood
capability whose evidence exists but whose *identity* needs something the
current model does not represent.

| Candidate | Missing axis | Source |
|---|---|---|
| Type III and type VI secretion systems | Co-localisation of homologous components in one architecture. NCBIfam's system-specific equivalogs change this argument and it needs re-running | [next release](proposal-next-gift-release.md), [genomic context](proposal-genomic-context.md) |
| PUL and CGC substrate assignment | Gene neighbourhood as evidence | [polysaccharide](proposal-polysaccharide-degradation.md) §12, [genomic context](proposal-genomic-context.md) |
| OxyR/PerR peroxide response | A regulon: regulator orthology identifies a sensor family, not its cognate lineage-specific targets | [next release](proposal-next-gift-release.md) |
| Calvin cycle, reductive TCA, 3-hydroxypropionate and 3-HP/4-HB cycle segments | Which spans are independently meaningful. Recorded as family placeholders, not GIFTs | [MetaCyc](proposal-metacyc-expansion.md) |
| Reductive glycine carbon fixation, as named | Direction. The same markers serve both directions and presence does not establish reductive flux | [MetaCyc](proposal-metacyc-expansion.md) |
| Trehalose biosynthesis variants | An unsettled donor boundary — UDP, ADP or GDP glucose contribute half the carbon and cannot silently merge into one route input | [MetaCyc](proposal-metacyc-expansion.md) |
| GIFT ontology or specialization edges | A non-anchor edge between GIFTs, amending invariant 2 | [protein degradation](proposal-protein-degradation.md) |
| Ferredoxin-route resolution in the TCA layer | A schema change to represent the electron carrier | [central cycles](proposal-central-metabolic-cycles.md) §6.7 |
| The electron-transfer component of a multicomponent oxygenase | A decided policy on whether an enzyme system must require it. Four curated systems say no — `SYS_12633_BENAB`, both anthranilate systems and `SYS_20357_HCAEF` curate the oxygenase alone — while [aromatic](proposal-aromatic-degradation.md) §9.3 refuses caffeine precisely because its system would be "missing its reductase component". Both positions cannot be right. The evidence is not the obstacle: `K11311` *antC*, `K18249` *andAa*, `K05710` *hcaC* and `K00529` *hcaD* have always been available, and `NF040810.1` *benC* is an equivalog with 10,067 hits for the one component KEGG never grouped. Adding the components is a `narrows` change | [discovery](proposal-ncbifam-discovery.md) §4.5 |

### The electron-acceptor boundary

A separate heading because it is a general rule rather than a candidate, it
decides several capabilities at once, and the seeding pass below missed it: the
refusal lives in prose and in a test rather than in a decision table, which is
exactly the failure mode this register exists to prevent.

> A capability whose completion requires an external terminal electron acceptor
> is out of scope. Curate the part of the chemistry that ends before the
> acceptor, and name the trait for what that part does.
> — [nitrogen compound catabolism](proposal-nitrogen-compound-catabolism.md) §8

| Candidate | Blocked because | Unblocks when | Source |
|---|---|---|---|
| `nitrate_respiration` | The acceptor clause, and separately `K00370`/`K00371` name the nitrite oxidoreductase NxrAB, so the marker cannot state direction | A completeness contract for respiration, plus a direction answer for Nar. NCBIfam may separate `narG` from `nxrA`, unchecked | §8, and [respiration](proposal-respiration-electron-acceptors.md) |
| `denitrification` | The acceptor clause; NO, N2O and N2 are successive acceptors | Same contract | §8 |
| `dnra` / `nitrite_ammonification` | The acceptor clause. Respiratory end to end | Same contract. No direction problem: `K03385` is specific | §8 |
| Taurine to hydrogen sulfide | The acceptor clause; DsrAB uses sulfite as terminal acceptor | Same contract | §8 |
| `oxygen_respiration` / terminal oxidases | The acceptor clause. No direction ambiguity in any of the five oxidase families | Same contract. The highest-value candidate in the group | [respiration](proposal-respiration-electron-acceptors.md) |
| Fumarate respiration | Recorded on the `FUMARATE` anchor itself: the anchor supports no fumarate respiration claim. The reaction is already curated as `succinate_fumarate_interconversion` | Same contract | `anchors.tsv` |
| Hydrogenases, dissimilatory sulfate reduction | Same clause, plus direction: `[FeFe]` and `[NiFe]` hydrogenase and DsrAB evidence does not state which way the enzyme runs | Same contract, and direction-resolving evidence | Not previously assessed; recorded here |

**This one is guarded by a test.** `test-nitrogen.R` asserts that the
respiratory nitrogen and sulfur accessions match no marker anywhere in the
database. Anyone curating them will find out; the point of the row is that they
find out first.

## 4. Refused on biology, and closed

These are not deferrals. Each was declined because the capability does not fit
what a GIFT is or what its type may claim, and no evidence release changes that.
They are listed so that a future pass does not re-litigate them by accident.

| Candidate | Why it is closed | Source |
|---|---|---|
| Erm 23S methylation, TetM/TetO ribosome protection, Van D-Ala-D-Lac replacement | Target alteration, protection and replacement. The drug is never converted, so none is chemical detoxification | [antimicrobial](proposal-antimicrobial-detoxification.md) §9 |
| Tripartite RND efflux as a defense GIFT | No chemical conversion, and the markers cannot name a pump or its substrates | [antimicrobial](proposal-antimicrobial-detoxification.md) §9.3 |
| CARD as a runtime namespace | Its organising axis is resistance phenotype, most content is inexpressible in the evidence layer, and the licence is incompatible | [antimicrobial](proposal-antimicrobial-detoxification.md) §4, §5, §10 |
| `gallate_biosynthesis` | No reaction exists to curate: Rhea 141 records gallate in nine reactions, none of them its formation from 3-dehydroshikimate | [shikimate](proposal-shikimate-aromatics.md) §5 |
| `succinate_formation`, `fumarate_formation`, `citrate_formation` | Each fires on chemistry that is not the capability named — `frdABCD` calls fumarate respirers positive, adenylosuccinate lyase makes fumarate in 93.8% of genomes | [central cycles](proposal-central-metabolic-cycles.md) |
| A `metabolic_cycle` GIFT type | Invariant 19 requires a completeness contract per type and a cycle has none of its own; invariant 18 says higher-order descriptions are derived | [central cycles](proposal-central-metabolic-cycles.md) |
| Curated cycle tables | The cycles are derivable from the anchor graph; curating them would let a stored circuit disagree with the graph | [central cycles](proposal-central-metabolic-cycles.md) §8.3 |
| Glutamate fermentation | Prevalence 0 and 31, and the claim is not what the markers state | [amino acid metabolism](proposal-amino-acid-metabolism.md) §12.3 |

---

## Coverage

Seeded from `proposal-amino-acid-metabolism.md`,
`proposal-antimicrobial-detoxification.md`, `proposal-aromatic-degradation.md`,
`proposal-central-metabolic-cycles.md`,
`proposal-compatible-solutes-heme-enterobactin-detoxification.md`,
`proposal-defense-gifts.md`, `proposal-metacyc-expansion.md`,
`proposal-next-gift-release.md`, `proposal-polysaccharide-degradation.md`,
`proposal-protein-degradation.md`, `proposal-regulatory-gifts.md`,
`proposal-shikimate-aromatics.md` and `proposal-structural-gifts.md`.
`proposal-ncbifam-discovery.md` added nine rows to section 1 and one to section
3 on 2026-08-25, and closed the NCBIfam retrigger on three of them.

The seeding pass read each proposal's decision tables. Where a proposal
discusses a refusal only in prose, it may not have a row yet; the source
documents remain authoritative and this register is an index over them, never a
replacement.

That limitation is not theoretical, and it has now cost two curation passes.
The electron-acceptor boundary above was missed by the seeding pass and
recovered only when an attempted respiration curation hit the test that guards
it. The cofactor-activation and biotin-precursor refusals were missed the same
way and recovered only when the 2026.22.1 release started curating candidates
they already covered. Prose refusals and test-guarded refusals
both need rows, and a curator adding one should search the test suite as well
as the proposals.

There is now a third place to search, and it is the worst of them. The Fe-only
nitrogenase refusal above lived in the `notes` column of a row in `gifts.tsv` —
inside the database, where nothing indexes it and no test guards it — and its
retrigger had already half fired before anyone read it. **Search the `notes`
columns of the source tables too.**
