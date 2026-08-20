# Reference database provenance

The initial source tables were curated on 2026-08-17.

- Rhea release 141: <https://www.rhea-db.org/>
- Rhea reaction cross-reference download:
  <https://ftp.expasy.org/databases/rhea/tsv/rhea2xrefs.tsv>
- KEGG module M00048: <https://www.kegg.jp/module/M00048>
- KEGG module M00049: <https://www.kegg.jp/module/M00049>
- KEGG module M00050: <https://www.kegg.jp/module/M00050>
- KEGG module M00051: <https://www.kegg.jp/module/M00051>
- KEGG module M00052: <https://www.kegg.jp/module/M00052>
- KEGG module M00016: <https://www.kegg.jp/module/M00016>
- KEGG module M00017: <https://www.kegg.jp/module/M00017>
- KEGG module M00018: <https://www.kegg.jp/module/M00018>
- KEGG module M00020: <https://www.kegg.jp/module/M00020>
- KEGG module M00021: <https://www.kegg.jp/module/M00021>
- KEGG module M00338: <https://www.kegg.jp/module/M00338>
- KEGG module M00609: <https://www.kegg.jp/module/M00609>
- KEGG orthology and gene-to-organism links: <https://rest.kegg.jp/>
- ChEBI release 253: <https://www.ebi.ac.uk/chebi/>

Rhea master reactions used by the five GIFTs are listed in `reactions.tsv`.
KEGG reaction and EC cross-references are normalized in `reaction_xrefs.tsv`.
Direction is curated per route in `route_reactions.tsv`; for example,
RHEA:14905 and RHEA:18445 are reversed for PRPP-to-IMP biosynthesis, while
RHEA:24296 and RHEA:10380 are reversed for UMP biosynthesis.

KEGG M00049 extends from IMP through AMP to ADP and ATP. gifter intentionally
uses only RHEA:15753 and RHEA:16853 because AMP is the declared output anchor.

KEGG M00050 extends from IMP through GMP to GDP and GTP. gifter ends the
guanylate GIFT at GMP, the first stable product establishing guanylate identity,
and excludes the broadly shared guanylate-kinase and nucleoside-diphosphate-
kinase reactions. The retained IMP-to-XMP and XMP-to-GMP chemistry uses
RHEA:11708 and the complete glutamine-dependent RHEA:11680 reaction. KEGG's
ammonia-dependent R01230 is a partial/alternative substrate mode of the same
K01951 enzyme and is not treated as a genomically distinct route.

KEGG M00051 contains fumarate-, quinone-, and NAD-dependent alternatives for
dihydroorotate oxidation. These are represented as three routes using
RHEA:30059, RHEA:30187, and RHEA:13513, respectively. KEGG R01868 also maps to
the generic-acceptor RHEA:18073; gifter uses the chemically specific quinone
reaction RHEA:30187 because the corresponding K00254 ortholog is annotated as
quinone-dependent.

Where gifter departs from KEGG module logic in a way that changes which
markers count as evidence, the decision, its evidence, and its effect on GIFT
calls are recorded in `database_changes.tsv` rather than here, linked to the
GIFTs affected. Release 2026.08.2 contains two such departures in M00051: the
PyrI regulatory subunit is no longer required for aspartate carbamoyltransferase,
and the PyrK electron transfer subunit is now required for NAD-dependent
dihydroorotate oxidation. This file remains the record of dataset-level
sources and pathway-derivation choices.

KEGG M00052 combines shared UMP/UDP phosphorylation and CTP/CDP
interconversion with the cytidylate-specific UTP-to-CTP step. gifter uses UTP
and CTP as the boundaries and retains only the complete glutamine-dependent CTP
synthase reaction RHEA:26426. This single reaction is kept as a GIFT because it
establishes cytidine nucleotide identity and is independently meaningful, not
because every reaction in an upstream module must become a trait. KEGG's
ammonia-dependent R00571 is part of the same K01937-catalysed chemistry and is
not treated as a separate genomic capability.


## Amino acid GIFTs (release 2026.09.1)

Nine serine, glycine, aspartate-family, cysteine and methionine capabilities
were curated on 2026-08-17. The boundary reasoning, its evidence and its effect
on calls are recorded in `database_changes.tsv`; the dataset-level derivation
choices are summarised here.

Reaction identity, direction and ChEBI participants come from Rhea release 141,
resolved through `rhea2kegg_reaction.tsv` and `rhea2ec.tsv`. Four reactions run
against their Rhea master equation and are curated as `reverse`: RHEA:14329
(phosphoserine aminotransferase), RHEA:24284 (aspartate-semialdehyde
dehydrogenase), RHEA:15757 and RHEA:15761 (homoserine dehydrogenase), together
with RHEA:15481, whose master runs glycine to serine.

Three reactions carry a KEGG reaction cross-reference but no EC number in Rhea,
so only the KEGG reference is recorded: RHEA:30931, RHEA:13965 and RHEA:27826.
No EC number was copied from KEGG into `reaction_xrefs.tsv`, because that table
holds identity resolved against Rhea.

KEGG M00018 and M00017 share the aspartate-to-homoserine trunk. gifter
curates that chemistry once, as `aspartate_semialdehyde_biosynthesis` and
`homoserine_biosynthesis`, and composes the threonine and methionine GIFTs
through the L-aspartate 4-semialdehyde and L-homoserine anchors. The
semialdehyde anchor is also where KEGG M00016 leaves the aspartate family, so
the lysine and diaminopimelate branch can attach without re-cutting a GIFT.

KEGG M00017 models only transsulfuration. Direct sulfhydrylation, in which
acylated homoserine reacts with inorganic sulfide, is curated as a separate
capability with a sulfide input anchor. The two are separate GIFTs rather than
routes of one GIFT because anchors are declared per GIFT and the two consume
different sulfur substrates. K01739 is deliberately not accepted for RHEA:27826
even though KEGG annotates MetB to R01288; the sulfhydrylase side activity of a
cystathionine gamma-synthase is not evidence that a genome assimilates sulfide.

KEGG assigns both R01776 and R01777 to K00651 and to K00641, so the succinyl
and acetyl specificity of homoserine activation is not recoverable at KO
resolution. Both markers are accepted for both acylation reactions and the
limitation is recorded in `component_markers.notes` rather than asserted away.

KEGG M00338 and the cysteine-forming tail of M00609 are curated as the two
routes of one GIFT. The four SAM-cycle steps of M00609 are excluded as a
different capability. The O-acetyl-L-serine route additionally requires serine
O-acetyltransferase, which M00609 omits because its diagram enters at
O-acetyl-L-serine.

L-homocysteine is declared as an input anchor only. Declaring it as an output,
or adding a methionine-to-homocysteine GIFT, closes the sulfur cycle and the
source validator rejects the database. See `database_changes.tsv`.

## External pathway references

`gift_xrefs.tsv` records how each curated GIFT relates to pathway records in
other resources, using the relation vocabulary `equivalent`, `subset_of`,
`superset_of`, `overlaps` and `related`. The relation is part of the biological
claim: a GIFT is bounded by declared anchors and is usually not the same object
as the pathway a reader arrives from.

The namespace is open. `KEGG_MODULE` and `KEGG_PATHWAY` accessions are curated
today, taken from the KEGG module and pathway listings retrieved on 2026-08-17.
MetaCyc identifiers are accepted by the schema but are not curated. The reason
recorded here through database 2026.17.1 — that no public MetaCyc endpoint could
be reached — was **corrected on 2026-08-18**: `https://websvc.biocyc.org/getxml`
returns full pathway records for objects addressed by ID, though the search
endpoint remains HTML- and captcha-gated, so records can be cited but not
discovered programmatically. The reason gifter cites no MetaCyc row is therefore
structural rather than practical: a pathway record fixes no input and output
boundary a genome can be scored against, states no alternative minimal routes as
separate objects, and carries no marker layer. gifter's boundaries come from where
genomes measurably differ. See `inst/doc/proposal-nitrogen-compound-catabolism.md`
section 4.

## Reaction identity, compartment, and mode (database 2026.09.2, schema 4)

Schema 4 adds structure that no current content exercises. It was added ahead of
the polysaccharide and sugar degradation layer, whose design is recorded in
`inst/doc/proposal-polysaccharide-degradation.md`.

`reactions.tsv` gains `reaction_id`. For every reaction curated so far it equals
the Rhea master, so nothing changed identity. It exists because Rhea coverage of
polymer-acting chemistry is incomplete: a polysaccharide is a substrate class
rather than a compound with a balanced equation, and many endo-acting glycoside
hydrolase reactions have no master entry. Such reactions will carry a curated
identifier and at least one cross-reference. No Rhea-shaped identifier is ever
minted for chemistry Rhea does not cover.

`anchors.tsv` gains `molecule` and `compartment`. All 19 anchors curated so far
are `unspecified`, with `molecule` equal to `anchor_id`. Compartment is a
curated boundary claim and not a genomic inference: annotation markers identify
chemistry, not localisation. When degradation content is added, an anchor will
be split by compartment only where the substrate can physically occupy both
locations and substrate-specific transporter markers exist to evidence the
crossing.

`gifts.tsv` gains `mode`. All content curated so far is `anabolic`. The
composition cycle check runs within a mode, because catabolism legitimately
returns to metabolites biosynthesis produces.

Planned evidence sources for the degradation layer, not yet used by any record:
the CAZy database for family definitions and characterised activities, and
dbCAN3 / dbCAN-sub for the family and subfamily assignments that annotation
pipelines emit. Earlier gifter releases are not an evidence source for that
content.

## Sugar degradation (database 2026.09.3)

Nine monosaccharide and uronate degradation GIFTs, the first catabolic content
in the database. Every accession was verified against the resource it names on
2026-08-18, through the KEGG REST API (`https://rest.kegg.jp/`) for orthology
and the Rhea web service (`https://www.rhea-db.org/rhea`) for reaction chemistry
and ChEBI participant identity. Anchor ChEBI identifiers are the participants of
the curated Rhea master reactions rather than generic entries for the same
substance.

Verification changed the content in two places. `araD` was recorded as K01786 in
the curation proposal; that identifier does not exist in KEGG, and the
L-ribulose-5-phosphate 4-epimerase orthologue is **K03077**. EC 5.3.1.5 and
EC 2.7.1.16 each map to two Rhea master reactions, and only the substrate-correct
one is curated: `RHEA:22816` rather than the glucose isomerase reaction
`RHEA:28546`, and `RHEA:22072` on L-ribulose rather than `RHEA:17601` on
D-ribulose.

Two KEGG modules match a curated boundary exactly and are recorded as
`equivalent`: M00632 for the Leloir pathway and M00061 for glucuronate
degradation. The other seven capabilities have no KEGG module, which is the
usual case for catabolism of a single sugar.

Curation decisions that depart from a mechanical reading of the source
resources — the exclusion of the biosynthetic GNE kinase from sialic acid
catabolism, and the optional status of aldose 1-epimerase — are recorded in
`database_changes.tsv` with their evidence and their effect on calls.

## Carbohydrate-active enzyme evidence

`fam-substrate-mapping.tsv` from the dbCAN database release
`db_v5-2-9_5-5-2026` is the reference for CAZy family and subfamily assignment,
substrate association, and characterised activity. It is retrieved from
`https://dbcan.s3.us-west-2.amazonaws.com/db_v5-2-9_5-5-2026/`, the release
pinned by `run_dbcan` (<https://github.com/bcb-unl/run_dbcan>), and covers 1017
family/substrate records across 44 high-level substrate classes.

No CAZy marker is curated yet. The file is recorded here because it is the
evidence base for the polysaccharide layer, and because the substrate classes it
defines are what the polymer anchors of that layer will be drawn from.

## Pentose uptake (database 2026.09.4)

D-xylose and L-arabinose ABC import, and the compartment split of those two
anchors. Transporter orthologues and transport chemistry were verified on
2026-08-18: KEGG K10543/K10544/K10545 (XylFGH), K10537/K10538/K10539 (AraFGH)
and K25045/K25046/K25047 (XacGHI, characterised on both pentoses); Rhea master
reactions RHEA:29899 and RHEA:30007, both carrying explicit `(out)` and `(in)`
participants.

Rhea represents a transport reaction with one ChEBI identifier on both sides of
the membrane. The anchor therefore identifies the substance and the
`compartment` column carries the location, which is why the two variants of one
sugar share `CHEBI:53455` or `CHEBI:17535`. The pentose anchors were moved from
anomer-specific identities to the generic sugar at the same time, so that the
transport and catabolic reactions act on the same declared substance.

Uptake was curated for these two substrates only. Fucose, galactose, mannose and
fructose are moved mainly by promiscuous carriers and were refused on marker
specificity; sialic acid, hexuronates and N-acetylglucosamine have specific
markers but no verifiable reaction identity for the translocation step. The
decisions and their evidence are in `database_changes.tsv`.

## Arabinoxylan and starch degradation (database 2026.10.1, restructured 2026.10.2)

Three polysaccharide GIFTs across two substrates: `xylan_degradation`,
`arabinoxylan_debranching` and `starch_degradation`. The 2026.10.1 release split
these into six single-reaction traits; that shape was retracted in 2026.10.2
because it made a GIFT equivalent to a reaction and left the substrate-level
question unanswerable. See `database_changes.tsv`.

**None of the six EC numbers has a Rhea master reaction.** EC 3.2.1.1, 3.2.1.8,
3.2.1.20, 3.2.1.37, 3.2.1.41 and 3.2.1.55 were all queried against the Rhea web
service on 2026-08-18 and returned nothing, because a polysaccharide is a
substrate class rather than a compound with a balanced equation. Each reaction
therefore carries a curated `reaction_id` and an EC cross-reference, which is
the case schema 4 made possible.

CAZy family assignments come from the pinned dbCAN mapping in
`data-raw/reference/`. Marker confidence is **derived from that file rather than
asserted**: for each family, the number of distinct EC numbers it carries across
all substrates is counted, and a family with one characterised activity is
recorded as `curated`, two or three as `high-confidence`, and four or more as
`ambiguous`. The count is written into each `component_markers.notes` entry so
the judgement can be re-checked. GH5 carries 28 distinct activities and GH13
carries 34, so neither is specific evidence for any one chemistry; GH52, GH120
and GH62 carry one each.

KEGG orthologues were verified separately and are recorded as `curated`. A
family hit and an orthology hit usually describe the same protein, so they are
alternative markers of one catalytic role rather than alternative enzyme
systems; see `database_changes.tsv`.

## CAZy subfamily evidence (database 2026.11.1)

Subfamily markers derive from the dbCAN-sub HMM library of release
`db_v5-2-9_5-5-2026`, via the pinned table in `data-raw/reference/`, whose
README documents the extraction. 267 subfamily evidence rows across the seven
catalytic components of the polysaccharide layer.

Confidence comes from two measured quantities rather than one asserted
judgement: `ec_fraction`, how dominant the EC is among the EC-annotated members
of the cluster, and `ec_members`, how many members support it. A cluster is
`curated` at a fraction of 0.9 or more with at least 10 supporting members,
`high-confidence` at 0.7 with at least 3, and `ambiguous` otherwise. The counts
are written into each `component_markers.notes` entry so the judgement can be
re-checked without returning to the source.

Two filters are applied when reading that table, and both matter. The CAZy class
must match the chemistry, so an esterase family is not accepted as evidence for
a glycosidase reaction even when its members carry that EC through a second
domain. Carbohydrate-binding modules are excluded entirely: a CBM cluster whose
members carry a xylanase EC reflects an appended binding domain, and a binding
module catalyses nothing.

Bare CAZy families are retained alongside the subfamilies as a lower-confidence
fallback, so a genome annotated only at family level still produces a call.
Precision comes from the subfamily rows; recall comes from the family rows.

## Facet classification (database 2026.11.1, schema 5)

The former free-text `category` column is replaced by a registered facet
vocabulary in `facet_terms.tsv`, assigned in `gift_facets.tsv` and
`anchor_facets.tsv`. `substrate_class` is single-valued so that it partitions
the database; `physiological_role`, `resource_origin`, `molecular_tier` and
`biomass_essential` classify without partitioning.

`gift_routes.tsv` gains `oxygen_requirement`. Every route curated so far is
`independent`: none of the curated chemistry needs or excludes oxygen, and
asserting otherwise would overclaim. Lytic polysaccharide monooxygenase routes,
when curated, will be `aerobic`.

## Typed GIFTs and structural content (database 2026.12.2, schema 6)

`gifts.tsv` gains a required `gift_type` column, and the structural, regulatory
and defense models gain their own source tables. Every previously curated GIFT
became `metabolic` unchanged.

### Structural content

`flagellar_apparatus` and `type_iva_pilus` are curated from KEGG orthology,
verified against the KEGG REST API on 2026-08-18. Each accession used here was
read back from `rest.kegg.jp` rather than transcribed from memory or from a
secondary source. KEGG supplies the orthology assignments; the decomposition
into structural functions, the choice of two flagellar architectures, and the
decision about what each claim excludes are gifter curation.

Provenance of the structural decomposition:

- flagellar export gate, basal body, C ring, hook, hook-filament junction,
  filament and stator follow the characterised enterobacterial and *Bacillus*
  flagellar apparatus;
- the L and P rings are curated as a separate diderm architecture because a
  monoderm envelope has no outer membrane for the L ring; this is an
  architectural alternative, not an optional part;
- the type IVa pilus decomposition follows the conserved T4aP machine:
  prepilin processing, major pilin, extension ATPase, inner membrane platform,
  PilMNOP alignment subcomplex and PilQ secretin, with retraction accessory.

### Refusals recorded with the content

`proton_driven_flagellar_apparatus` and `sodium_driven_flagellar_apparatus` are
**not** curated. KEGG assigns *Vibrio cholerae* PomA (`vch:VC_0892`) and PomB
(`vch:VC_0893`) to K02556 and K02557, the same orthologues as *Escherichia coli*
MotA and MotB, so KO evidence does not separate proton- from sodium-driven
motors. MotX (K21217) and MotY (K21218) are specific to the sodium-type polar
T ring but evidence a scaffold rather than an ion channel, and are absent from
the *Bacillus* MotPS sodium motor. The refusal, and what would license the
split, are recorded in `database_changes.tsv` and in
`inst/doc/proposal-structural-gifts.md`.

`K02424` (*fliY*) is refused as evidence for the flagellar switch: KEGG assigns
it to an L-cystine transport binding protein, so it is not specific to the
capability it would be accepted for.

`K02655` (*pilE*) is accepted for the major pilin at `ambiguous` confidence
only. It is the major pilin in *Neisseria* and a minor pilin in *Pseudomonas*,
so the accession does not by itself establish the protein's role; the confidence
ordering carries that doubt to any call resting on it.

### Regulatory and defense

No regulatory or defense content is curated. Their source tables ship with
headers and no rows, and the open evidence questions are recorded in
`inst/doc/proposal-regulatory-gifts.md` and
`inst/doc/proposal-defense-gifts.md`.

## Regulatory and defense content (database 2026.12.3, schema 6)

Five GIFTs fill the two typed models that previously shipped with schema only.
The schema is unchanged; this is a content release. Every accession was read
back from `rest.kegg.jp` on 2026-08-18 rather than transcribed. KEGG supplies
the orthology assignments and the gene counts; the decomposition into functions,
the choice of alternative circuits and mechanisms, and what each claim excludes
are gifter curation.

### Measurements, not assumptions

Two curation decisions rest on gene counts per genome taken from the KEGG REST
API on 2026-08-18, and both changed the design:

| Accession | Counts | Consequence |
|---|---|---|
| K03406 generic MCP | *E. coli* K-12 **0**, *S.* Typhi 1, *B. subtilis* 8, *P. aeruginosa* 21, *V. cholerae* 34 | The chemoreception function accepts a generic **or** a characterised chemoreceptor, so an *E. coli* annotation is not called receptor-less; and the same spread is the evidence that the accession cannot name a chemoeffector. |
| K07636 `phoR`, K07657 `phoB`, K07658 `phoP` | sensor single-copy in the five genomes carrying it; the two regulator groups mutually exclusive; *B. subtilis* BSU29110 adjacent to BSU29100 | The phosphate response is curated as two circuits sharing a sensor rather than one PhoR/PhoB circuit that would call *B. subtilis* negative. |

These are nine reference genomes, not a calibration study. They answer the
specific worry about paralogue absorption and nothing wider.

### Refusals recorded with the content

- **Ligand-specific chemoreception beyond aspartate.** K05876 (Trg) covers ribose
  and galactose in one group; K05877 (Tap) covers an unresolved dipeptide range;
  K03406 covers everything. Only K05875 (Tar) is anchored on a single
  characterised primary ligand, so only `aspartate_chemoreception` is curated.
  It accepts K05875 and refuses K03406.
- **K07660** is refused as a phosphate-regulon regulator. It shares the gene name
  *phoP* with K07658 and is the response regulator of the magnesium-sensing
  PhoP/PhoQ system, present in *E. coli* and *Salmonella* and absent from
  *B. subtilis* — the opposite distribution from the phosphate regulator.
- **The target sequence of a type I restriction-modification system** is not
  claimed. HsdS specificity comes from variable target recognition domains that
  the orthology group does not resolve.
- **K07475**, the HD nuclease module of a split Cas3, is refused as evidence of
  the complete nuclease-helicase; K07012, the fused protein, is accepted.
- **CheV (K03415)** is refused as a substitute for CheW, because it occurs
  alongside CheW in the systems that have it rather than replacing it.
- **Interference by a CRISPR-Cas system** is not claimed. Interference needs a
  CRISPR array to supply guide RNAs, an array is a repeat-spacer locus detected
  by structure, and no protein accession evidences one. The claim is narrowed to
  the encoded machinery and says so in its description.

### External links

`chemotaxis_signal_transduction` and `aspartate_chemoreception` are `subset_of`
KEGG map02030, and `phosphate_starvation_response` is `subset_of` map02020. The
two defense GIFTs carry no link: KEGG describes prokaryotic defense systems in a
BRITE hierarchy, which is not a pathway record whose boundaries could be
compared, the same reason `collagen_cleavage` and `type_iva_pilus` carry none.

## Short-chain fatty acid formation, 2026-08-18

Curated in release 2026.13.1 as six GIFTs. The full evidence test, including the
candidates that were refused, is
[the SCFA proposal](../../doc/proposal-scfa-biosynthesis.md).

### Sources used

- KEGG module M00579: <https://www.kegg.jp/module/M00579>. The only module in
  the layer; KEGG has none for butyrate formation and none for propionate
  formation, so five of the six GIFTs are gifter curation rather than a KEGG
  import.
- KEGG orthology-to-gene links, `https://rest.kegg.jp/link/genes/ko:<KO>`,
  reduced to organism codes and intersected locally. 49 orthology groups over
  the 11856 organisms that carry at least one of them; the KEGG genome list
  (11949 entries) supplied genus attribution.
- KEGG reaction records for the cross-references in `reaction_xrefs.tsv`, taken
  from each orthology group's own `REACTION` field rather than assigned by hand.
- Rhea release 141 for all eighteen reactions.
- ChEBI release 253 for the six new anchors.
- InterPro and NCBIfam, `https://www.ebi.ac.uk/interpro/api/`, retrieved
  2026-08-18: entry records and protein match listings for TIGR03948, TIGR02706
  and TIGR02707.
- MetaCyc was consulted and is **not** cited by any row. Its pathway pages
  returned no content without a subscription on 2026-08-18, and the boundaries
  it would have supplied are already fixed by Rhea and by the anchor cuts below.

### A new marker namespace, for one component

`TIGRFAM TIGR03948` is the first non-KO, non-CAZy marker in the metabolic layer,
and it carries the whole specificity of `butyrate_formation`. KEGG assigns EC
2.8.3.8 and EC 2.8.3.9 to the same pair of accessions, K01034 and K01035, so no
orthology group separates the enzyme that releases butanoate from the
acetoacetate degradation transferase of *E. coli*. The consequences were
measured before the namespace was changed rather than after:

| Rule | Organisms | What it gets wrong |
|---|---:|---|
| acetyl-CoA core + Ptb/Buk | 366 | 120 *Bacillus*, 16 *Geobacillus*; none ferment to butyrate |
| acetyl-CoA core + K01034/K01035 | 344 | includes *B. subtilis* 168 |
| any terminal KO, in 39 genomes of canonical butyrate-producing genera | 9 | *F. prausnitzii*, *R. intestinalis* and *A. rectalis* all negative |
| `TIGR03948` | 178 proteins / 171 proteomes | led by *Faecalibacterium*, *Roseburia*, *Eubacterium*, *Anaerostipes*; no *Bacillus*, *Escherichia*, *Salmonella* or *Pseudomonas* |

No R change was needed: `.infer_marker_namespace()` already recognised
`^TIGR[0-9]{5}$`, and `marker.namespace` has never carried a `CHECK`.

### Reaction identity: four choices worth checking

Rhea covers every reaction in the layer, but three of its EC-level masters are
parents whose acyl chain length is unspecified, and picking a parent would have
let a route claim a product its chemistry does not fix.

- **RHEA:30071**, `butanoate + acetyl-CoA = butanoyl-CoA + acetate`, is used
  rather than **RHEA:13381**, the EC 2.8.3.8 master `an acyl-CoA + acetate`.
- **RHEA:26558**, `(3S)-3-hydroxybutanoyl-CoA = (2E)-butenoyl-CoA + H2O`, is
  used rather than **RHEA:52664**, the generic short-chain master that EC
  4.2.1.150 maps to. It is also not RHEA:17849, which is the (3R) reaction.
- **RHEA:16197** (NADP) is used for the dehydrogenase because KEGG assigns
  K00074 to R01976. The NAD-dependent **RHEA:30799** is the same enzyme's
  alternative cofactor mode, is annotated to the same orthologue, and is
  therefore not a genomically distinct route — the same treatment KEGG's
  ammonia-dependent R01230 receives in the guanylate GIFT.
- **RXN_LACTATE_COA_TRANSFER** carries no Rhea master. Rhea's EC 2.8.3.1 master
  RHEA:23520 covers only the propanoate/acetyl-CoA transfer, so the
  lactate-accepting transfer of the acrylate pathway is identified by KEGG
  R01449 and EC 2.8.3.1 through the nullable-master path.

One anchor is more specific than the reaction that consumes it. `PROPANEDIOL`
is the (S) diol (CHEBI:29002), because that is what the lactaldehyde reductase
produces and it matches the existing (S)-`LACTALDEHYDE` anchor; RHEA:14569 is
stereochemically unspecified in Rhea (CHEBI:16997). The boundary is stated at
the higher specificity and the reaction at the lower, which is recorded here
rather than resolved by weakening the anchor.

### Measurements, not assumptions

| Question | Counts | Consequence |
|---|---|---|
| Does one E1 architecture cover the dehydrogenase complex? | alpha/beta E1 with E2 and E3 in 5406 organisms; fused AceE-type E1 with E2 and E3 in 4813; union 9518 | RHEA:28042 carries **two** enzyme systems. Accepting either alone would call *E. coli* or *B. subtilis* negative for chemistry it has. |
| Is PorABCD enough for the ferredoxin route? | four-subunit PorABCD in 499; fused NifJ-type in 2202 | Two systems again. Most gut anaerobes carry only the fused protein. |
| Do all three pyruvate routes earn their place? | 10961 of 11856 organisms complete at least one | Yes, and the three differ in oxygen requirement, which is a route property. |
| Should EtfAB be required of the butanoyl-CoA dehydrogenase? | K03521 with K03522 in 7729 organisms; 20 of the 39 reference butyrate-producer genomes carry both while 31 complete the core | **No.** They are the generic *fixA*/*fixB* orthologues; requiring them costs recall and adds no specificity. |
| Is the acrylate route worth curating at its coverage? | pct with both lcdAB subunits in 13 organisms, all characterised acrylate-pathway producers; acryloyl-CoA reductase K20143 in 4 of them | Curated with the reductase **required**. Nine genomes are reported incomplete with RHEA:34471 named, following the serine phosphatase precedent. |

### Refusals recorded with the content

- **The butyrate kinase route.** Ptb and Buk serve branched-chain acyl-CoA
  metabolism in aerobic Bacillota. At sequence-family level the picture is the
  same as at KO level: TIGR02707 matches 2279 proteins with *Bacillus* the
  second most frequent genus, TIGR02706 matches 573 with *Bacillus* second after
  *Clostridium*. No namespace change repairs it.
- **K01034 and K01035** are refused as evidence for the butyrate terminal step,
  for the reason in the table above.
- **The succinate (Wood-Werkman) route to propionate.** Its markers are the
  genes KEGG module M00741 uses in the *degradative* direction. Mutase with
  decarboxylase and a candidate CoA-transferase is complete in 177 organisms,
  or 293 including the carboxyltransferase K17489, led by *Corynebacterium*
  (70), *Escherichia* (19), *Cutibacterium* (16) and *Klebsiella* (13);
  *Bacteroides thetaiotaomicron* is negative.
- **Lactate and formate** are out of scope by chain length and chemical class,
  not by evidence. Pyruvate formate-lyase is nonetheless curated, as one route
  of `pyruvate_to_acetyl_coa`, where formate is a co-product rather than a claim.
- **Valerate, caproate and the branched SCFAs.** No chain-length-specific marker
  exists for chain elongation, and the branched acids share the *Bacillus*
  enzymes refused above.
- **A compartment for any SCFA anchor.** The only candidate transporter marker
  is K07034, a family-level uptake annotation for a bidirectional channel, and
  there is no butyrate or propionate transporter accession at all. All six
  anchors are therefore `unspecified`, `gift_profile.cross_feeding_output` stays
  0 across the layer, and acetate cross-feeding — the textbook case — remains
  something the model cannot say. Revisit behind substrate-specific transporter
  evidence, the same licence that governs oligosaccharide anchors.

### External links

`acetate_formation` is `equivalent` to M00579; the same boundaries and the same
two reactions, with direction recorded per route and stated not to be evidenced
by the markers. The other five are `subset_of` a KEGG pathway map: map00620 for
the pyruvate node, map00650 for butyrate, map00640 for the propionate GIFTs and
for propanediol formation. M00741 carries no link, because it describes the
opposite direction of chemistry that no curated GIFT contains.

### The acetate node is declared reversible, 2026-08-18

`acetate_interconversion` (renamed from `acetate_formation` during review)
declares `ACETYL_COA` and `ACETATE` as **both** input and output. This is the
first GIFT to use `mode = 'interconversion'`, and the reason is evidential
rather than stylistic.

KEGG M00579 records one direction, acetyl-CoA to acetate. The same
phosphotransacetylase and acetate kinase run the reaction towards acetyl-CoA in
a genome growing on acetate — *Escherichia coli* does exactly this at high
acetate — and no marker separates the two physiologies. Two ways of hiding that
were rejected:

- **One-way anchors** assert a direction the markers do not support. The GIFT's
  own description already said so; the boundary contradicted it.
- **Two GIFTs**, a formation and an assimilation, assert a distinction the same
  two accessions cannot make, which is what invariant 16 forbids.

The route is *not* mirrored. `ACETATE_PTA_ACKA` records one traversal, and a
flipped copy would complete on identical markers, report two complete routes for
one capability, and make closest-route selection non-deterministic. Direction
lives in the anchors for composition and in `route_reaction.orientation` for
chemistry, and those answer different questions.

`orientation` is worth stating plainly here, because it reads as a
contradiction: it is relative to how Rhea writes each reaction's own equation,
not to the direction of the GIFT. Rhea writes acetate kinase in its named,
acetate-consuming direction, so the two steps chain only if one is flipped:

```text
RHEA:19521  acetyl-CoA + phosphate = acetyl phosphate + CoA   forward
RHEA:11352  acetate    + ATP       = acetyl phosphate + ADP   reverse
            acetyl-CoA -> acetyl phosphate -> acetate
```

Both masters are written towards acetyl phosphate. One of them has to be
reversed for the route to exist at all, and the `reverse` tag is that bookkeeping
rather than a claim about pathway direction.

`butyrate_formation` keeps its directional name despite the same evidential
limit — NCBIfam TIGR03948 explicitly includes the transferase *Syntrophomonas
wolfei* uses to grow **on** butyrate. It is not declared reversible because
running the acetyl-CoA core backwards is beta-oxidation, a different route
with different enzymes, so the assembly direction is a claim the curated
chemistry does make. The asymmetry is deliberate and is recorded here rather
than left to be rediscovered.

## Organic acid and neutral fermentation product formation, 2026-08-18

Curated in release 2026.14.1 as six GIFTs. The full evidence test, including the
five candidates that were refused and the reason the citric acid cycle cannot be
anchored, is
[the organic acid proposal](../../doc/proposal-organic-acid-formation.md).

### Sources used

- KEGG orthology-to-gene links, `https://rest.kegg.jp/link/genes/ko:<KO>`,
  reduced to organism codes and intersected locally. 59 orthology groups over
  the 11855 organisms that carry at least one of them; the KEGG genome list
  (11949 entries) supplied genus attribution.
- KEGG orthology names, `https://rest.kegg.jp/find/ko/<KO>`. One of them is
  evidence in its own right: K00239, K00240 and K00241 are named `sdhA, frdA`,
  which is why no succinate formation trait is curated.
- KEGG reaction-to-pathway links, `https://rest.kegg.jp/link/pathway/rn:<R>`,
  for the `gift_xrefs.tsv` rows.
- Rhea release 141 for all nine reactions, with the ChEBI identifiers of the
  five new anchors read out of the equations that use them rather than assigned
  by hand.
- ChEBI release 253.
- No KEGG module covers any of these six boundaries, and MetaCyc is not cited.

### The layer's result: a direction that is evidenced, not asserted

The SCFA layer had to declare acetate an interconversion because Pta–AckA runs
both ways on one pair of genes. Lactate is the first fermentation end product
curated here where the markers themselves carry the direction, and the reason is
chemical: forming lactate is a cytoplasmic NADH-consuming reduction, while
consuming it feeds electrons to a quinone or a cytochrome.

| Direction | Enzyme | KO | Organisms |
|---|---|---|---:|
| forming | L-lactate dehydrogenase, NAD, EC 1.1.1.27 | K00016 | 4143 |
| forming | D-lactate dehydrogenase, NAD, EC 1.1.1.28 | K03778 | 3133 |
| consuming | L-lactate dehydrogenase, quinone (`lldD`) | K29125 | 3388 |
| consuming | L-lactate dehydrogenase, cytochrome | K00101 | 194 |
| consuming | D-lactate dehydrogenase, quinone (`dld`) | K03777 | 1257 |
| consuming | D-lactate dehydrogenase, cytochrome | K00102 | 2664 |

Only 573 organisms carry both K00016 and K29125. Every lactic acid bacterium
checked carries the forming group and not the consuming one; *Escherichia coli*,
*Salmonella* Typhimurium and *Pseudomonas aeruginosa* are the reverse. The four
consuming groups are recorded as refused markers, not accepted as alternatives.

D-lactate formation is deferred rather than curated: K03778 is specific to the
right chemistry but its leading genera are *Pseudomonas* (224), *Streptomyces*
(158) and *Burkholderia* (90), obligate aerobes running the reaction
oxidatively. The (R)-lactate anchor is reached through the racemase instead,
which is what the organisms actually do — of the ten KEGG genomes behind
`propionate_formation_acrylate`, eight carry K22373 and only two carry K03778.

### Refusals recorded with the content

| Candidate | Best marker set | Organisms | Why refused |
|---|---|---:|---|
| Succinate formation, `frdABCD` | K00244–K00247 with a carboxylase, malate dehydrogenase and fumarase | 1049 | *Vibrio* 91, *Escherichia* 70, *Klebsiella* 55 — fumarate respirers. *Bacteroides*, *Prevotella* and *Fibrobacter*, the dominant gut succinate producers, are all negative |
| Succinate formation, fused group | K00239/K00240 accepted as alternatives | 7276 | 61% of the universe, led by *Streptomyces*, *Pseudomonas*, *Bacillus* and *Chlamydia*. This is "has a citric acid cycle" |
| Fumarate formation | K01756 (`purB`); K01679 (`fumC`) | 11115; 9098 | 93.8% of organisms. gifter already curates the fumarate-releasing chemistry inside `purine_core_biosynthesis` and `adenylate_biosynthesis` |
| Citrate formation | K01647 (`gltA`) | 8467 | 71% of organisms; citrate is a cycle intermediate, not an excretion product |
| Formate formation | K00656 + K04069 | 2843 | Not an evidence failure. Anchors are per GIFT, and pyruvate formate-lyase is one of three routes of `pyruvate_to_acetyl_coa` |

Of the 1041 genomes carrying `frdABCD`, 943 also carry `sdhABCD`: the split is a
paralogue duplication inside one clade, not a functional partition across
bacteria, so it cannot infer direction anywhere else.

### The structural finding: the citric acid cycle may not be anchored

Checked against the validator rather than argued. Six catabolic GIFTs spanning
citrate → 2-oxoglutarate → succinate → fumarate → malate → oxaloacetate →
citrate close a within-mode loop and `.find_graph_cycle()` reports it. Unlike
the sulfur layer, there is no weak boundary to demote to input-only, because no
acid in the cycle is only ever consumed — and the cycle runs oxidatively,
reductively and as a branched horseshoe in different organisms, so no single
direction is curatable.

Declaring a `FUMARATE` anchor on the GIFTs whose curated reactions already
involve it adds two edges, `purine_core_biosynthesis` and
`adenylate_biosynthesis` into `pyrimidine_core_biosynthesis`, both chemically
true and both meaningless. It would also overclaim: only one of the three
curated pyrimidine routes uses fumarate.

The constructive half is that a metabolite does not need an anchor to be
modelled. `citrate_fermentation` passes through oxaloacetate and does not anchor
it; `malolactic_fermentation` and `citrate_fermentation` take malate and citrate
as **input-only** boundaries, which makes no claim about how the genome obtained
them. `tests/testthat/test-organic-acid.R` asserts that no citric acid cycle
metabolite is a declared output anchor.

### Evidence rests on the specific step, twice

Both decisions repeat the butyrate precedent.

- **Acetoin.** K01652 is named `ilvB, ilvG, ilvI` — the anabolic branched-chain
  amino acid synthase, in 9341 organisms. The acetolactate synthase step is
  curated with `required = 0` so the pyruvate boundary stays truthful, its
  marker mapping is recorded `ambiguous`, and the trait rests on acetolactate
  decarboxylase K01575 (1649 organisms), which exists only for this pathway.
- **Citrate.** The trait is the lyase, not the transporter. *E. coli* K-12
  carries CitT and is aerobically Cit-negative because the gene is not expressed
  under oxygen; gifter models gene content, not regulation, so requiring K09477
  would look like a phenotype claim without being one.

### External links

Five of the six GIFTs carry a `KEGG_PATHWAY` reference as `subset_of`
(map00620 Pyruvate metabolism; map00650 Butanoate metabolism for acetoin). No
KEGG module covers any curated boundary in this layer.

`citrate_fermentation` carries **no** external link, and the gap is real rather
than an omission: R00362 has no pathway link at all, and the citrate lyase
orthology groups appear only in map02020, the two-component system map, which
describes the CitAB regulator rather than the chemistry.

## Vitamin biosynthesis, 2026-08-18

Curated in release 2026.15.1 as twenty GIFTs covering vitamins B1, B2, B3, B5,
B6, B7, B9, B12 and K2. The full evidence test, the twelve refusals, and the
implementation record are in
[the vitamin proposal](../../doc/proposal-vitamin-biosynthesis.md).

### Sources used

- KEGG orthology-to-gene links, `https://rest.kegg.jp/link/genes/ko:<KO>`,
  reduced to organism codes and intersected locally. 126 orthology groups scored
  over all 10151 bacterial genomes of the KEGG release of 2026-08-18.
- KEGG BRITE `br:br08601` for the domain and phylum attribution used to separate
  bacterial from eukaryotic prevalence. It is what disqualified two candidates:
  the tryptophan route to NAD is complete in 545 organisms of which 490 are
  eukaryotes, and neither ascorbate module completes in a single bacterium.
- KEGG module records `M00115`–`M00931` for pathway organisation and for the
  `gift_xrefs.tsv` relations. Their `DEFINITION` expressions were **not** used as
  boundaries: M00125 defines riboflavin completeness without lumazine synthase or
  riboflavin synthase, M00119 defines pantothenate without PanC or PanD, and
  M00127 defines thiamine as ThiF+ThiS+ThiI. Every route here was assembled from
  the reaction content instead.
- KEGG per-organism KO assignments, `https://rest.kegg.jp/link/ko/<org>`, for the
  18-genome validation panel, and `https://rest.kegg.jp/list/<org>` for the gene
  names that explain two of its results.
- Rhea release 141 for all 94 reactions. One hundred EC numbers were queried and
  every one returned a master, so no reaction in this layer uses the nullable
  `rhea_master` path. Two reactions are identified by a Rhea entry rather than by
  KEGG's EC assignment: `RHEA:33343` (ThiO, no EC in Rhea) and `RHEA:42440`
  (aspartate dehydrogenase, EC 1.4.1.29, the iminosuccinate-forming chemistry
  that feeds quinolinate synthase rather than KEGG's EC 1.4.1.21).
- ChEBI release 253 for the 31 new anchors.
- InterPro/Pfam for one refusal only: `PF00590` is *Tetrapyrrole
  (Corrin/Porphyrin) Methylases*, one family spanning CbiE, CbiF, CbiH, CbiL,
  CobM and diphthine synthase, so it cannot evidence any individual corrin
  methyltransferase step.
- MetaCyc is not cited.

### The layer's result: the orphan step

Four reactions in this layer are certain chemistry with no marker at the
specificity of the step. They are curated with `route_reaction.required = 0`,
which keeps them visible in a trace while keeping them out of completeness:

| Reaction | Step | Measured cost of requiring it |
|---|---|---|
| `RHEA:25197` | riboflavin ribityl phosphatase | 7943 → 2682 bacterial genomes |
| `RHEA:25302` | folate dihydroneopterin triphosphate diphosphatase | 5898 → 1634 |
| `RHEA:25597` | menaquinone MenH | classical route 3109 → 1355, with the next row |
| `RHEA:26309` | menaquinone DHNA-CoA thioesterase | as above |

The rule that keeps this honest is that the marker is never widened instead. The
folate dihydroneopterin monophosphatase step is **not curated at all**, because
the only markers offered for it (`K01077`, `K01113`) are generic alkaline
phosphatases assigned in 3202 and 2770 bacterial genomes.

### Measurements, not assumptions

- Nucleotide loop without a ring: 4139 genomes carry the loop, 3044 of them no
  corrin ring at all. This is why cobalamin is four GIFTs and not one.
- Lower ligand: of 1081 genomes completing ring, cobinamide arm and loop, 538
  carry BluB. A cobamide is not vitamin B12 unless the ligand is
  dimethylbenzimidazole.
- Corrin ring recall: *Propionibacterium freudenreichii* is called incomplete
  because `PFREUD_07710` (`cysG_cbiX`) and `PFREUD_07700`
  (`cobJ_cbiE_cbiG_cbiH`) are fusions KEGG assigns to none of the component
  orthology groups.
- Isochorismate synthase: *Bacteroides thetaiotaomicron* annotates `BT_4700` as
  `entC` and carries no `menF`. Accepting `K02361` for the reaction raises the
  complete classical route from 1355 to 3109 genomes.
- Thiazole sulfur carrier: requiring ThiS and ThiF drops the branch from 5396 to
  1554 genomes, and neither marker is thiamine-specific.
- The layer partitions bacteria rather than describing them: 1087 of 10151
  genomes complete none of the nine vitamin capabilities, 228 complete all nine,
  and half complete four or fewer.

### Refusals recorded with the content

Twelve, in `database_changes.tsv`: a single cobalamin trait, vitamin C, the
tryptophan route to NAD, biotin precursor supply, the anaerobic route to the
lower ligand, cobalamin uptake, alkaline phosphatase as folate evidence,
cofactor activation of every vitamin in the layer, the GMP-to-GTP
phosphorylation, glyceraldehyde 3-phosphate as an anchor of vitamin B6, ThiS and
ThiF as required components, and vitamin provision as a trait of its own.

### External links

`gift_xrefs.tsv` records 25 KEGG module links for this layer. Only five are
`equivalent`; the rest are `subset_of`, `superset_of`, `overlaps` or `related`,
which is the honest summary of how far the module boundaries are from the
capabilities a genome actually gains or loses.

## Circular central metabolism, 2026-08-18

Database 2026.16.1, schema unchanged at 6. Four segment GIFTs of the oxidative
citric acid cycle, four anchors, fourteen reactions. Full assessment in
`inst/doc/proposal-central-metabolic-cycles.md`.

This layer **reverses a recorded finding**. The organic acid assessment
concluded that citric acid cycle intermediates cannot be anchors. That was right
about product claims — whether a genome can be said to form and release citrate,
fumarate or succinate — and those five refusals stand unchanged. It was wrong
about capability claims, which is what every other gifter GIFT makes.

### Sources used

- **KEGG orthology-to-gene links**, `https://rest.kegg.jp/link/genes/ko:<KO>`:
  67 orthology groups over the 11 783 organisms carrying at least one of them.
- **KEGG gene-to-orthology**, `https://rest.kegg.jp/link/ko/<gene>`, for four
  individual genes. These four lookups carry the citrate synthase decision.
- **KEGG modules** `M00009`, `M00010`, `M00011` for the external boundaries.
- **Rhea release 141** for all fourteen reactions, every KEGG reaction and EC
  cross-reference, and every ChEBI identifier, each taken from the `chebi-id`
  column of a reaction that uses it.

### Measurements, not assumptions

| Question | Counts | Consequence |
|---|---|---|
| Does segmenting the cycle distinguish genomes? | all **16 of 16** configurations of the four segments occupied; complete cycle 7415 (62.9%), none 1529 (13.0%), branched `U--F` 195 led by *Helicobacter* 80 | Yes. A monolithic trait collapses 4368 genomes into one uninterpretable class. |
| Can the succinate/fumarate direction be evidenced? | `K00239` is named by KEGG **`sdhA, frdA`**, 8047 organisms; dedicated `frdAB` 1059, almost all Enterobacteriaceae | **No.** The segment is `interconversion`; two directional GIFTs would be complete on identical markers in 8047 genomes. |
| Is `K01647` enough for citrate synthase? | strict 8425 (71.5%) and *B. thetaiotaomicron*, *S. aureus*, *Synechocystis* negative; with `K01659` 9717 (82.5%) and *Streptococcus* 64, *Listeria* 48 positive | Neither setting is right. `K01659` is accepted at `ambiguous` confidence — and KEGG's own `M00010` definition lists it as a citrate synthase alternative. |
| Which aconitase groups are needed? | `K01681` ∪ `K01682` alone is 4565 and calls *B. subtilis* and *M. tuberculosis* negative; adding `K27802` gives 10 031 | All three. `K27802` was split out of `K01681` by KEGG. |
| Should the cytochrome b anchor be required of succinate dehydrogenase? | `K00239`+`K00240` 8047; adding `K00241` 7645 | **No.** 402 genomes would be called negative on a poorly conserved membrane subunit. |
| Do the three routes to succinate earn their place? | dehydrogenase complex 6902, ferredoxin oxidoreductase 3288, decarboxylase bypass 1420; 8932 complete at least one | Yes. The bypass is what makes *M. tuberculosis* and *C. glutamicum* positive without an E1o component. |
| Is exposing citrate safe? | gifter's own edge derivation closes `citrate_fermentation -> pyruvate_to_acetyl_coa -> citrate_synthesis -> citrate_fermentation` | **No.** Citrate stays an internal intermediate and an input-only boundary. |

### The acyclicity check was scoped, not relaxed for this content

Two synthetic reversible GIFTs sharing one fixture anchor — no citric acid
chemistry — already failed the build, because `interconversion` declares every
anchor in both roles and two of them therefore cycle by construction. The check
now covers the three directed modes only. Under the curated content every
directed mode remains acyclic, which is asserted against the compiled database
rather than a fixture.

### The cycle is derived

No circuit table was added. The oxidative citric acid cycle is an elementary
cycle of the composition graph that `gift_cycles()` finds from four anchor
declarations. Only its name is curated, as the new multi-valued `metabolic_cycle`
GIFT facet, so structure and naming cannot drift apart.

### External links

`gift_xrefs.tsv` records 13 links for this layer. One is `equivalent`
(`acetyl_coa_to_oxoglutarate` to `M00010`, the same three reactions between the
same endpoints); the other twelve are `subset_of`, because gifter cuts `M00011`
at succinate and fumarate and cuts `M00009` four ways.

## Nitrogen compound catabolism (database 2026.18.1, schema 6)

Fourteen GIFTs covering ureide, inorganic nitrogen, methylated amine and
organosulfonate catabolism, plus a boundary amendment to the two amino sugar
GIFTs. The assessment behind them, including everything refused, is
`inst/doc/proposal-nitrogen-compound-catabolism.md`.

### Sources

- Rhea release 141, `https://ftp.expasy.org/databases/rhea/tsv/rhea2ec.tsv` and
  the Rhea REST API, retrieved 2026-08-18. All 37 reactions of this layer carry
  a Rhea master; none needed the nullable `rhea_master` path.
- ChEBI release 253 for the 16 new anchors. Each identifier was taken from the
  participant list of the Rhea reaction that uses it rather than by name lookup,
  which is why several anchors name a protonation or tautomer state:
  `CHEBI:15678` is (S)-allantoin rather than the racemate, `CHEBI:58389` is
  trimethylammonium, and `CHEBI:17775` is the urate species `RHEA:21368` uses.
- KEGG orthology and `link/genes/ko:` gene-to-organism sets, retrieved
  2026-08-18 from `https://rest.kegg.jp/`. Prevalence figures in
  `database_changes.tsv` are intersections of those sets with the 10 151
  bacterial organism codes of BRITE `br08601`, computed locally. KEGG module
  completeness was not used.
- KEGG module `M00531` and pathway maps `map00230`, `map00220`, `map00910`,
  `map00260`, `map00330`, `map00430` and `map00680`, listed 2026-08-18.
- distillR 1.x `GIFT_db` as installed, read 2026-08-18, used only as the
  coverage checklist that enumerated the twelve candidate compounds. It is not
  an evidence source, and section 12 of the proposal records three of its
  definitions that do not survive the marker specificity invariant.
- MetaCyc is not cited by any row; see the correction above.

### Where gifter departs from KEGG

`M00531` is the one module in this layer whose boundaries match a GIFT exactly,
and it is linked `equivalent`. Everything else is `subset_of`. `map00910` is the
clearest case: it carries assimilation, respiration, denitrification and
nitrification on one map, and gifter curates only the first, because the other
three need an electron acceptor gifter does not model.

Two KEGG orthology groups were examined and refused rather than used. `K00370`
is named by KEGG as `nitrate reductase / nitrite oxidoreductase` — one accession
for two opposite reactions — and `K01485` as `cytosine/creatinine deaminase`,
where the cytosine activity is the common one. Both refusals are recorded in
`database_changes.tsv` with the genome counts behind them.

### The orphan steps

Three route steps carry `required = 0`, covering two reactions.
The OHCU decarboxylase appears in both urate routes and is discounted in each,
because the step also proceeds spontaneously to racemic allantoin. The betainyl-CoA thioesterase of the carnitine route has one
orthology group, `K27497`, which is bifunctional with the first step of the same
route; requiring it drops the capability from 944 genomes to 256.

## Shikimate-derived aromatic biosynthesis (database 2026.17.1, schema 6)

Three GIFTs — chorismate, salicylate and indole-3-acetate — plus a refusal of
gallate biosynthesis and a new `biosynthetic_family` facet. The assessment
behind them, including everything refused and deferred, is
`inst/doc/proposal-shikimate-aromatics.md`.

### Sources

- **Rhea release 141**, via the REST search API, retrieved 2026-08-18. All ten
  reactions of this layer carry a Rhea master; none needed the nullable
  `rhea_master` path. Every KEGG reaction and EC cross-reference was taken from
  the Rhea record, and the four ChEBI identifiers from the `chebi-id` column of
  a reaction that uses each participant: `CHEBI:58702` phosphoenolpyruvate from
  `RHEA:14717`, `CHEBI:30762` salicylate from `RHEA:27874`, `CHEBI:57912`
  L-tryptophan from `RHEA:16165` and `CHEBI:30854` (indol-3-yl)acetate from
  `RHEA:34371`.
- **KEGG release of 2026-08-18** (11 949 genomes). Orthology definitions from
  `get/ko:`, prevalence from `link/genes/ko:` intersected with the bacterial and
  archaeal leaves of BRITE `br08601`, which gives the same 10 151 bacterial and
  470 archaeal denominators the vitamin layer used. Module `M00022` and pathway
  maps `map00400`, `map01053` and `map00380` for the external links only.
- **NCBIfam/InterPro**, retrieved 2026-08-18, for `TIGR00507` (InterPro
  `IPR011342`), the one non-KO marker of this layer.
- Individual gene records `mtu:Rv2552c` and `syn:slr1559`, which carry the
  RefSeq annotation "shikimate 5-dehydrogenase" and no KO, and `stm:STM2405`,
  which KEGG assigns to `K04103` under the annotation "putative thiamine
  pyrophosphate enzymes". Those three lookups carry the two hardest decisions of
  the layer.

### Measurements, not assumptions

| Question | Counts | Consequence |
|---|---|---|
| Should the shikimate dehydrogenase step be required? | Route 5420 with it, **7644** without; the 2224 in the gap include 201 of 213 Cyanobacteriota and 1061 of 1642 Actinomycetota | **No.** `required = 0`. The gap is a KO coverage hole, confirmed on two genomes whose gene is annotated and unassigned. |
| Does adding `TIGR00507` and `K05887` help? | `K05887` moves the route by 180 bacteria; `TIGR00507` reaches genomes with no KO at all | Both accepted, `K05887` at `ambiguous` confidence. `K25901` refused: EC 1.1.1.24 is a different Rhea master. |
| Should the pathway be cut at 3-dehydroquinate? | Second segment without the first: **119** bacteria, but **270** archaea, 266 of them carrying `K11646` | **No** for bacteria, and the archaeal route is excluded rather than accommodated: it consumes different precursors, so it cannot be a route between these anchors. |
| Is `K13830` worth carrying from M00022? | **0** of 10 151 bacteria and 0 of 470 archaea | Dropped. It is the eukaryotic AROM polypeptide. |
| Are PchA/PchB and MbtI two routes? | KEGG assigns `K04781` both EC 5.4.4.2 and EC 4.2.99.21; 104 of 109 `pchA` genomes also carry `pchB` | **No.** Same two transformations, one bifunctional protein — the PabBC shape, curated at the system layer. |
| What does sharing `RHEA:18985` cost menaquinone? | ICS step moves 4047 to 4203, but only **7** genomes gain menaquinone | Acceptable, and recorded rather than hidden. The eight remaining *men* steps supply the specificity. |
| Is `K04782` standing in for chorismate mutase? | 90.3% of its carriers also carry a separate chorismate mutase KO, against an 84.6% baseline; 706 of 1017 carry no isochorismate synthase at all and cannot complete the route | **No**, and the ones that could not complete the route are excluded by route logic rather than by marker judgement. |
| Can the indole-3-pyruvate route be evidenced? | `K04103` in 648 bacteria, 417 of them Enterobacteria, assigned in *Salmonella* to a putative ThDP enzyme; the other two steps are a generic aminotransferase and a generic aldehyde dehydrogenase | **No.** Refused, with the tryptamine, nitrile and side-chain oxidase routes. |
| Does the broad amidase belong in the auxin route? | 49 bacteria on `K21801` alone, **86** with `K01426` added; `K01426` alone matches 4948 | Accepted at `ambiguous` confidence only, because `K00466` upstream already bounds the route to 92 genomes. |
| Can gallate biosynthesis be evidenced at all? | Rhea has **9** gallate reactions and **0** forming it from 3-dehydroshikimate; KEGG has 8 gallate KOs, all degradative or plant | **No.** Refused for want of a reaction identity, before the marker question arises. |

### Refusals recorded with the content

`gallate_biosynthesis`, the three alternative auxin routes, `K25901` for the
shikimate dehydrogenase step and `K13830` for the multifunctional steps are each
recorded in `database_changes.tsv` or in the marker note that refuses them, not
only in the proposal.

### External links

`gift_xrefs.tsv` records four links for this layer. `M00022` is `overlaps`
rather than `equivalent` — the endpoints match but gifter does not require the
shikimate dehydrogenase step, accepts YdiB, and drops `K13830`. The three
pathway maps are `subset_of`, because each carries chemistry beyond the curated
boundary: `map00400` continues to the aromatic amino acids, `map01053` to the
assembled siderophores, and `map00380` to every other fate of tryptophan.

## Amino acid metabolism, release 2026.19.1

Curated 2026-08-19 against KEGG release of 2026-08-18 (11 949 genomes, of which
10 151 bacterial, taken from BRITE `br08601`), Rhea release 141 and ChEBI
release 253. Twenty-eight GIFTs: eighteen biosynthetic, completing the fifteen
proteinogenic amino acids gifter did not cover, and ten degradation or
transformation capabilities. The full assessment, including the twelve
candidates that were refused or deferred, is
[the amino acid metabolism proposal](../../doc/proposal-amino-acid-metabolism.md).

### KEGG modules consulted

M00015, M00016, M00019, M00023, M00024, M00025, M00026, M00028, M00040, M00045,
M00432, M00525, M00526, M00527, M00535, M00570, M00763, M00844. KEGG supplied
pathway organisation and orthology assignment; every reaction identity,
direction and cross-reference comes from Rhea.

### Where gifter's boundaries are its own, and why

| Decision | KEGG | gifter | Reason |
|---|---|---|---|
| Lysine | four modules from L-aspartate to L-lysine, each repeating the aspartate trunk | one `dap_biosynthesis` with four routes, cut at meso-diaminopimelate, plus `lysine_biosynthesis_dap` | The four are alternative implementations of one capability: 51.4, 5.6, 6.8 and 17.2% of bacterial genomes separately, 75.3% as routes of one GIFT. meso-DAP is also the peptidoglycan cross-link residue. |
| Branched-chain | M00019 fuses valine and isoleucine because the enzymes are shared | cut at 3-methyl-2-oxobutanoate and at 2-oxobutanoate, one GIFT per amino acid | The shared enzymes act on different substrates, so the reactions differ; the 2-oxo acid supply is what separates the traits, and 2-oxoisovalerate was already an anchor pantothenate consumed. |
| Leucine | M00432 stops at 2-oxoisocaproate | continues to L-leucine | The amino acid is the capability; the transamination is the enzyme already curated for valine. |
| Threonine deamination | inside M00570, as a step of isoleucine biosynthesis | its own catabolic GIFT, composed into isoleucine through the 2-oxobutanoate anchor | The chemistry is a deamination wherever it runs. Curating it twice would duplicate a reaction. |
| Aromatic transamination | requires `K00832` or `K00838` | accepts `K00832`, `K05821`, `K00812`, `K00813`, `K11358`, `K00826` | Requiring the KEGG pair calls phenylalanine in 2296 genomes where the aryl skeleton is in 7796. Recorded as `DBC-20260819-AROMATIC-TRANSAMINASE-WIDENED`. |
| Glutamine | inside ammonium assimilation | its own GIFT, sharing the glutamine synthetase reaction | Four curated GIFTs consume the amide nitrogen, and the GS-GOGAT route consumes its glutamine internally, so the two cannot compose through an anchor. |
| DapB cofactor | `R04198` (NADH) and `R04199` (NADPH) | `RHEA:35331` only | One orthology group serves both, so a second route would multiply the four diaminopimelate routes with no genomic discrimination. Recorded in the reaction description. |
| Arogenate routes | M00040, M00910 | not curated | `K01850` and `K15849` are annotated in no bacterial genome. |
| LysW ornithine route | M00763 | not curated | `K19412` is annotated in no bacterial genome. |

### Refusals recorded with the content

Tyramine formation (no bacterial orthology group for tyrosine decarboxylase),
tryptamine formation (only the polyspecific aromatic decarboxylase `K01593`),
p-cresol formation (32 bacterial genomes on `K18427`+`K18428`), glutamate
fermentation to butyrate (no genome completes either route at KO level), and the
promiscuous PLP enzymes as evidence for cysteine desulfidation are refused in
the proposal; the last is recorded in `database_changes.tsv` as
`DBC-20260819-CYSTEINE-SULFIDE-UNDERCALLED` because it bounds a curated claim.

### External links

`gift_xrefs.tsv` records 33 links for this layer. `equivalent` is used only
where the boundaries match exactly (M00015, M00023, M00026, M00028, M00535,
M00844, M00045, and M00024/M00025 where only the marker set is wider);
`subset_of` where gifter curates part of a module (M00016, M00019 twice, M00570
twice, M00027); `overlaps` where the diaminopimelate branch crosses all four
lysine modules without matching any of their boundaries; `superset_of` where it
continues past one (M00432); and `related` for the two routes refused on
evidence. Capabilities with no module at all -- alanine, aspartate, asparagine,
glutamine, and six of the ten catabolic GIFTs -- link to the KEGG pathway map as
`overlaps`.

## Nitrogen fixation, sulfate assimilation and glyoxylate bypass, release 2026.20.1

Curated 2026-08-20 against Rhea release 141, ChEBI release 253 and the KEGG
REST records retrieved that day. The full candidate assessment and the
non-metabolic deferrals are in
[the release proposal](../../doc/proposal-next-gift-release.md).

### Primary database records

- Rhea `RHEA:21448` and `RHEA:55543`; KEGG M00175 and R05185/R12084 for the Mo
  and V nitrogenase routes.
- Rhea `RHEA:18136`, `RHEA:24152`, `RHEA:11724`, `RHEA:21976`, `RHEA:13804`
  and `RHEA:23132`; KEGG M00176 for sulfate activation and assimilatory
  reduction.
- Rhea `RHEA:13245` and `RHEA:18181`; KEGG M00012 for the glyoxylate cycle.
- ChEBI `CHEBI:17997` dinitrogen, `CHEBI:16189` sulfate and `CHEBI:15562`
  D-threo-isocitrate. Existing ammonium, sulfide, succinate, malate and
  acetyl-CoA anchors retain their ChEBI identities.

### Specialist and primary literature

- Dos Santos PC et al. *BMC Genomics* 2012, “Distribution of nitrogen fixation
  and nitrogenase-like sequences amongst microbial genomes.” The comparative
  minimum signature is NifHDKENB.
- Yang J et al. *PNAS* 2014, “Reconstruction and minimal gene requirements for
  the alternative iron-only nitrogenase in Escherichia coli.” Used to assess,
  and ultimately defer, the Fe-only architecture rather than generalise the Mo
  minimum.
- Jasniewski AJ et al. *mBio* 2021, “Specificity of NifEN and VnfEN for the
  assembly of nitrogenase active site cofactors in Azotobacter vinelandii.”
  Supports the separate Mo and V cofactor scaffolds and shared NifB precursor.
- Bick JA et al. *Applied and Environmental Microbiology* 2000,
  “Identification of a new class of 5'-adenylylsulfate (APS) reductases from
  sulfate-assimilating bacteria.” Supports the direct assimilatory APS branch
  and its distinction from dissimilatory APS reductase.
- Abby SS et al. *Scientific Reports* 2016, “Identification of protein
  secretion systems in bacterial genomes.” Used for the T3SS/T6SS deferral:
  TXSScan/MacSyFinder combines HMM profiles with system-level genomic
  organisation to distinguish homologous machinery.

### Curation decisions not imported from those sources

gifter chose the molecular cut points, which assembly proteins are indispensable
to its nitrogen-fixation claim, the four route materialisations for sulfate,
the refusal of `K00390` as a branch-resolving marker, and the isocitrate re-cut.
KEGG M00175 does not require the NifB/EN assembly proteins; gifter does because a
positive call must support a complete active-site architecture rather than a
catalytic-subunit checklist. KEGG K00390 spans EC 1.8.4.8 and EC 1.8.4.10;
gifter stores those reaction-specific EC markers instead. KEGG M00012 accepts
K19282; gifter defers it because its two-reaction malyl-CoA implementation is
not an enzyme-system alternative for direct malate synthase.

All marker-level acceptances and refusals are recorded in
`component_markers.tsv`, `markers.tsv` and `database_changes.tsv`, linked to the
affected GIFTs in `change_gifts.tsv`.

## Compatible solutes, heme b, enterobactin and detoxification, release 2026.20.2

Curated 2026-08-20 against Rhea release 141, ChEBI release 253 and KEGG records
retrieved that day. The complete candidate assessment, boundaries, route table,
refusals and retrigger conditions are in
[the release proposal](../../doc/proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### Primary database records

- Rhea `RHEA:11160`, `RHEA:16901` and `RHEA:17281`; KEGG M00033; MetaCyc
  P101-PWY for the ectoine tail.
- Rhea `RHEA:19865`, `RHEA:18257`, `RHEA:15425`, `RHEA:25576`,
  `RHEA:27409`, `RHEA:62000`, `RHEA:22584`, `RHEA:43436`, `RHEA:49572`
  and `RHEA:56516`; KEGG M00121 and M00926; MetaCyc HEME-BIOSYNTHESIS-II,
  HEMESYN2-PWY and PWY-7766 for heme b.
- Rhea `RHEA:18985`, `RHEA:11112`, `RHEA:23824` and `RHEA:30571`; KEGG
  map01053; MetaCyc ENTBACSYN-PWY for the two enterobactin segments.
- Rhea `RHEA:17433`, `RHEA:33051`, `RHEA:17769`, `RHEA:13505`,
  `RHEA:20369` and `RHEA:15305`; KEGG M00555; MetaCyc BETSYN-PWY and
  PWY-3722 for choline oxidation.
- Rhea `RHEA:19069` and `RHEA:25245`; MetaCyc PWY-5386 for the
  glutathione-dependent methylglyoxal mechanism.
- Rhea `RHEA:20696`, `RHEA:20309` and the generic hydroperoxide reaction
  `RHEA:62620`; MetaCyc DETOX1-PWY and DETOX1-PWY-1 for complete superoxide
  detoxification.
- ChEBI `CHEBI:58515` L-ectoine, `CHEBI:60344` heme b, `CHEBI:36654`
  2,3-dihydroxybenzoate, `CHEBI:77805` enterobactin and `CHEBI:15354`
  choline, taken from the accepted Rhea reaction participants.

The Rhea 141 `rhea2kegg_reaction.tsv` file does not map KEGG R09489 to
`RHEA:27409`, so no KEGG reaction xref was asserted for the HemG reaction.
Rhea leaves HemJ's electron acceptor abstract in `RHEA:62000`, and that lower
chemical specificity is stated in the reaction and evidence notes.

### Specialist and primary literature

- Richter AA et al. *Frontiers in Microbiology* 2019, PMID 31921013, for the
  reversible EctB reaction and the EctABC tail.
- Boynton TO et al. *Biochemistry* 2009, PMID 19583219, for HemG; Kato K et al.
  *PNAS* 2010, PMID 20823222, for HemJ; Dailey HA et al. *PNAS* 2015,
  PMID 25646457, for the HemY-HemH-HemQ coproporphyrin pathway.
- Shaw-Reid CA et al. *Chemistry & Biology* 1999, PMID 10375542, for EntB,
  EntD, EntE and EntF assembly-line roles.
- Ozyamak E et al. *Molecular Microbiology* 2010, PMID 21143325, for the two
  glutathione-dependent glyoxalases; Ko J et al. *Journal of Bacteriology*
  2005, PMID 16077126, for the broad reductases that were assessed and refused.
- Panek HR and O'Brian MR *Journal of Bacteriology* 2004, PMID 15547258, and
  Mishra S and Imlay JA *Archives of Biochemistry and Biophysics* 2012,
  PMID 22609271, for catalase and Ahp peroxide clearance; Eitinger T
  *Journal of Bacteriology* 2004, PMID 15516600, for the NiSOD maturation
  limitation; Kurtz DM and Coulter ED 2002, PMID 12072973, for the unresolved
  superoxide-reductase electron-delivery context.
- Boch J et al. *Journal of Bacteriology* 1996, PMID 8752328, for the GbsAB
  choline-to-betaine architecture.
- Rehm BHA and colleagues' class-specific PhaC experiments, PMID 15205419,
  PMID 24564904 and PMID 21261834, for the PHB specificity refusal.

### Access and prevalence record

Anonymous requests to the addressed MetaCyc pathway pages and BioCyc web
service redirected to account creation on 2026-08-20. The identifiers and
reaction memberships were cross-checked against the pathway export, but this
release does not repeat the earlier claim that the web service remains
anonymously accessible. A KEGG `link/genes/ko:` prevalence pass was also
attempted; DNS resolution failed during the pass, and the failed empty results
were discarded rather than reported as zero prevalence. No acceptance or
refusal in this release depends on a prevalence threshold.

### Curation decisions not imported from those sources

gifter chose the ASA cut for ectoine, the UROGEN_III cut and independent route
materialisation for heme, the 2,3-dihydroxybenzoate split for enterobactin, and
the point at which both defense mechanisms are chemically complete. It also
requires EntD inside the enterobactin system and both stages of superoxide
detoxification. The database does not import MetaCyc pathway completeness as a
call.

`K14085` is refused for betaine-aldehyde specificity, `K00518` for incomplete
NiSOD maturation, and broad methylglyoxal reductases for substrate ambiguity.
The requested PHB GIFT is not present: `K03821` identifies PHA polymerases with
different chain-length preferences and cannot license a PHB-specific claim.
Those durable refusals and their retriggers are in the proposal; accepted
call-changing decisions are in `database_changes.tsv` and `change_gifts.tsv`.

## Siroheme branch, release 2026.20.3

The release implements only the evidence-complete upstream half of the
MetaCyc-expansion recommendation. `siroheme_biosynthesis` is a metabolic,
anabolic GIFT from `UROGEN_III` to `SIROHEME`. The proposed downstream
`siroheme_to_heme_b` GIFT is refused because its first reaction requires two
homologous subunits that the current maintained marker vocabulary cannot tell
apart.

### Primary database records

- Rhea release 141 `RHEA:32459`, `RHEA:15613` and `RHEA:24360` define the
  three curated reactions and their master directions. The ferrochelatase
  master is written as siroheme dechelation, so the route uses it in reverse.
- Rhea identifies siroheme as `CHEBI:60052`. That exact microspecies is the
  new anchor; no internal precorrin or sirohydrochlorin intermediate is
  promoted to an anchor.
- MetaCyc 30.0 `PWY-5194` has the same `UROGEN_III`-to-siroheme boundaries.
  Its four direct reaction records split the two sequential methyl transfers;
  gifter uses the chemically equivalent overall methyltransferase master
  `RHEA:32459`, followed by the dehydrogenase and ferrochelatase masters.
- KEGG M00846 was retrieved on 2026-08-20. It supports multifunctional CysG
  `K02302`; methyltransferases `K00589`, `K02303`, `K02496`, `K13542` and
  `K13543`; bifunctional Met8 `K02304`; and split SirC `K24866` plus SirB
  `K03794`. The GIFT starts downstream of the module's glutamyl-tRNA head.

The official KEGG genome and KO-to-gene tables contained 10,151 bacterial and
470 archaeal genomes on 2026-08-20. The accepted route expression called 4,161
bacteria and one archaeon: 3,742 bacteria carried multifunctional CysG, and a
further 419 bacteria plus one archaeon carried a complete accepted split
implementation. This is an evidence audit, not a prevalence threshold.

### Specialist and primary literature

- Woodcock et al., PMID 9461500, established the separate methyltransferase and
  dehydrogenase/chelatase domains of multifunctional CysG.
- Schubert et al., PMID 11980703, established bifunctional Met8 dehydrogenase
  and ferrochelatase activity.
- Raux et al., PMID 12408752, established the split SirA, SirC and SirB
  methyltransferase, dehydrogenase and ferrochelatase system.
- Kuhner et al., PMID 24669201, showed that AhbA and AhbB together form the
  siroheme decarboxylase, followed by AhbC and AhbD.
- Palmer et al., PMID 24865947, resolved the decarboxylase as an AhbA-AhbB
  heterodimer and showed why both subunits are part of the complete system.

### Refusal and under-call boundaries

`siroheme_to_heme_b` is not implemented. Both experimentally required
*Methanosarcina barkeri* genes, `Mbar_A1459` and `Mbar_A1460`, are assigned to
the same KEGG orthology group, `K22225`. gifter's evidence model evaluates the
presence of a namespaced accession and cannot require two distinct observed
genes carrying that accession. Adding `K22225` to two components would
therefore let one gene complete the heterodimer. Among 190 bacterial and 122
archaeal genomes carrying the full KEGG M00847 marker expression, 45 bacteria
and three archaea had only one `K22225` gene row, demonstrating the false
positive rather than merely anticipating it. Reconsider the downstream GIFT
only with AhbA/AhbB-distinguishing markers, a fusion-specific marker, or an
explicit multiplicity-aware evidence contract.

The upstream GIFT is also deliberately conservative. CbiX-family sequences can
insert iron, cobalt or nickel into sirohydrochlorin, and primary sequence alone
does not consistently separate those metal specificities in archaea. Only the
iron-specific `K03794` SirB group is accepted for the split ferrochelatase.
This under-calls real archaeal siroheme synthesis but does not promote a broad
chelatase into an iron-specific claim.

### Curation decisions not imported from those sources

gifter chose `UROGEN_III` and `SIROHEME` as the only boundaries, treats the
two MetaCyc methyl-transfer records as the one overall Rhea reaction they
jointly instantiate, and lets the same multifunctional marker support separate
reaction-specific components without collapsing the reaction layer. A positive
call says only that the complete siroheme-forming chemistry is encoded. It does
not claim cofactor incorporation, reductase activity, sulfur or nitrogen
assimilation, alternative heme formation, expression, activity or phenotype.
