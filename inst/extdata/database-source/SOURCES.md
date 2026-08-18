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

KEGG M00049 extends from IMP through AMP to ADP and ATP. giftr intentionally
uses only RHEA:15753 and RHEA:16853 because AMP is the declared output anchor.

KEGG M00050 extends from IMP through GMP to GDP and GTP. giftr ends the
guanylate GIFT at GMP, the first stable product establishing guanylate identity,
and excludes the broadly shared guanylate-kinase and nucleoside-diphosphate-
kinase reactions. The retained IMP-to-XMP and XMP-to-GMP chemistry uses
RHEA:11708 and the complete glutamine-dependent RHEA:11680 reaction. KEGG's
ammonia-dependent R01230 is a partial/alternative substrate mode of the same
K01951 enzyme and is not treated as a genomically distinct route.

KEGG M00051 contains fumarate-, quinone-, and NAD-dependent alternatives for
dihydroorotate oxidation. These are represented as three routes using
RHEA:30059, RHEA:30187, and RHEA:13513, respectively. KEGG R01868 also maps to
the generic-acceptor RHEA:18073; giftr uses the chemically specific quinone
reaction RHEA:30187 because the corresponding K00254 ortholog is annotated as
quinone-dependent.

Where giftr departs from KEGG module logic in a way that changes which
markers count as evidence, the decision, its evidence, and its effect on GIFT
calls are recorded in `database_changes.tsv` rather than here, linked to the
GIFTs affected. Release 2026.08.2 contains two such departures in M00051: the
PyrI regulatory subunit is no longer required for aspartate carbamoyltransferase,
and the PyrK electron transfer subunit is now required for NAD-dependent
dihydroorotate oxidation. This file remains the record of dataset-level
sources and pathway-derivation choices.

KEGG M00052 combines shared UMP/UDP phosphorylation and CTP/CDP
interconversion with the cytidylate-specific UTP-to-CTP step. giftr uses UTP
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

KEGG M00018 and M00017 share the aspartate-to-homoserine trunk. giftr
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
MetaCyc identifiers are accepted by the schema but are not curated yet: they
could not be verified against a public MetaCyc endpoint during this release,
and unverified pathway accessions are not recorded.

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
pipelines emit. Earlier giftr releases are not an evidence source for that
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
decision about what each claim excludes are giftr curation.

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
are giftr curation.

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
