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
genome universe moves, read section 2; when an architectural axis opens, read
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
| `siroheme_to_heme_b`, the Ahb route | `K22225` matches both AhbA and AhbB, so a jointly required heterodimer cannot be proven | **Condition met.** NCBIfam separates `NF040708.3` *ahbA* and `NF040707.3` *ahbB* | [MetaCyc](proposal-metacyc-expansion.md) |
| Flagellar coupling ion, H⁺ versus Na⁺ | `K02556`/`K02557` cover both MotA/MotB and PomA/PomB | A profile or ortholog separates the sodium-driven stator. NCBIfam does not | [structural](proposal-structural-gifts.md) |
| Chemotaxis toward a named chemoeffector | A generic MCP accession cannot name a ligand | Per-receptor evidence. Partly available: `aspartate_chemoreception` already curates Tar, and NCBIfam grades *tar* and *tsr* separately | [regulatory](proposal-regulatory-gifts.md) |
| CRISPR subtype identity | A generic Cas protein cannot license a subtype, and an array is not in the evidence layer | Subtype-specific component evidence, plus a decision on array detection | [defense](proposal-defense-gifts.md) |
| Aminoglycoside modification | No marker resolves the drug class; the resolvable level is one drug | A claim named for the chemistry rather than the drug class would not need this | [antimicrobial](proposal-antimicrobial-detoxification.md) §8 |
| Macrolide esterase `ereA` | No KO exists | A profile in an admitted namespace covers it. NCBIfam unchecked | [antimicrobial](proposal-antimicrobial-detoxification.md) |
| Caffeine N-demethylation | The required reductase has no KO | Same | [aromatic](proposal-aromatic-degradation.md) |
| Polyhydroxybutyrate biosynthesis | `K03821` names PHA synthases across substrate classes and cannot identify PHB | An equivalog-grade profile specific to the PHB synthase | [compatible solutes](proposal-compatible-solutes-heme-enterobactin-detoxification.md) |
| Nine aromatic capabilities — toluene, benzene, xylene, cumate, *p*-cymene, biphenyl, carbazole, naphthalene, terephthalate | Ring-hydroxylating dioxygenase families cannot say which ring they hydroxylate | Not by a finer family: the enzymes are promiscuous as proteins. Only substrate-resolving evidence of a kind gifter does not have | [aromatic](proposal-aromatic-degradation.md) |
| Elastin, keratin, albumin, actin, glutelin, tropomyosin, troponin cleavage | EC 3.4.24.26 hydrolyses several of these; for most, no orthologue exists at all | Substrate-resolving peptidase evidence. MEROPS is the resource to assess | [protein degradation](proposal-protein-degradation.md) |
| Tryptophan to tryptamine, as named | Aromatic amino acid decarboxylase evidence does not single out the substrate | Substrate-resolving decarboxylase evidence | [amino acid metabolism](proposal-amino-acid-metabolism.md) §12.2 |
| Complex glycan degradation beyond the curated set | Broad CAZy families do not resolve substrate identity | dbCAN subfamily coverage at the required specificity, or PUL context — which is section 3 | [next release](proposal-next-gift-release.md) |
| SusC/SusD substrate assignment | The pair is a transport machine, not a substrate claim | Never from context alone; explicitly refused, not deferred | [polysaccharide](proposal-polysaccharide-degradation.md) §4.6 |
| Variant- and SNP-based resistance | Resistance is a residue and the evidence layer has no accession for a residue | An evidence model with residue-level identity, which is not on the roadmap | [antimicrobial](proposal-antimicrobial-detoxification.md) §9.4 |

## 2. Blocked on prevalence

Retrigger: a change to the reference genome universe, or an explicit decision to
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

The seeding pass read each proposal's decision tables. Where a proposal
discusses a refusal only in prose, it may not have a row yet; the source
documents remain authoritative and this register is an index over them, never a
replacement.

That limitation is not theoretical. The electron-acceptor boundary above was
missed by the seeding pass and recovered only when an attempted respiration
curation hit the test that guards it. Prose refusals and test-guarded refusals
both need rows, and a curator adding one should search the test suite as well
as the proposals.
