# Why each GIFT is delimited this way

This index separates each current GIFT's **scope** from the **reason for that scope**. It summarizes the source definitions in [`gifts.tsv`](../extdata/database-source/gifts.tsv) and [`gift_anchors.tsv`](../extdata/database-source/gift_anchors.tsv) at database release 2026.39.1. A link under **Record** leads to the curation argument, and, where retained, to the analysis script and result table. The historical prevalence counts in those documents belong to their stated source releases and are not re-estimated here. The pinned Rhea, ChEBI and marker-accession sources are described in [reference database provenance](../extdata/database-source/SOURCES.md).

The scope of a metabolic GIFT is its declared input and output anchors. Commas separate co-declared anchors; they do not list every reaction participant. For `interconversion`, the same anchors appear on both sides by design. Structural, regulatory and defense GIFTs are scoped by complete machinery instead.

Search this page by `gift_id`. The reasons summarize the **current** source rows; the linked records carry the detailed chemistry, marker decisions, alternatives and limitations. When a current definition changes, update its entry here while retaining the dated curation record. This index makes no new biological calls or review sign-off.

## Reference database provenance

Primary reasoning record: [SOURCES.md](../extdata/database-source/SOURCES.md).

### `purine_core_biosynthesis` — PRPP to IMP

- **Scope:** `PRPP` → `IMP`; `anabolic` metabolic capability.
- **Why this limit:** IMP is the common branchpoint from which the separately curated adenylate and guanylate GIFTs begin. The PRPP-to-IMP route follows [KEGG M00048](https://www.kegg.jp/module/M00048); its alternative complete routes remain within this one capability.
- **Record:** curation record: [SOURCES.md](../extdata/database-source/SOURCES.md).

### `adenylate_biosynthesis` — IMP to AMP

- **Scope:** `IMP` → `AMP`; `anabolic` metabolic capability.
- **Why this limit:** Atomic branch derived from KEGG M00049; ends at AMP because shared nucleotide phosphorylation is intentionally excluded.
- **Record:** curation record: [SOURCES.md](../extdata/database-source/SOURCES.md).

### `guanylate_biosynthesis` — IMP to GMP

- **Scope:** `IMP` → `GMP`; `anabolic` metabolic capability.
- **Why this limit:** Atomic branch derived from KEGG M00050; ends at GMP because shared nucleotide phosphorylation is intentionally excluded.
- **Record:** curation record: [SOURCES.md](../extdata/database-source/SOURCES.md).

### `pyrimidine_core_biosynthesis` — Glutamine and PRPP to UMP

- **Scope:** `GLUTAMINE`, `PRPP` → `UMP`; `anabolic` metabolic capability.
- **Why this limit:** UMP is the first common pyrimidine product before the separately curated cytidylate branch. The [KEGG M00051](https://www.kegg.jp/module/M00051) boundaries are retained, while alternative dihydroorotate oxidation chemistries are separate complete routes.
- **Record:** curation record: [SOURCES.md](../extdata/database-source/SOURCES.md).

### `cytidylate_biosynthesis` — UTP to CTP

- **Scope:** `UTP` → `CTP`; `anabolic` metabolic capability.
- **Why this limit:** Atomic cytidylate-forming capability derived from KEGG M00052; shared UMP/UDP phosphorylation and CTP/CDP interconversion are intentionally excluded.
- **Record:** curation record: [SOURCES.md](../extdata/database-source/SOURCES.md).

## Curation proposal: serine, threonine, cysteine and methionine GIFTs

Primary reasoning record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

### `serine_biosynthesis` — 3-phosphoglycerate to serine

- **Scope:** `PG3` → `SERINE`; `anabolic` metabolic capability.
- **Why this limit:** Boundaries of KEGG M00020 retained. The phosphoserine phosphatase step is kept required even though a fifth of serA/serC genomes carry no recognised phosphatase orthologue; the chemistry is required and the missing reaction is reported rather than silently scored away.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

### `glycine_biosynthesis` — Serine to glycine

- **Scope:** `SERINE` → `GLYCINE`; `anabolic` metabolic capability.
- **Why this limit:** No KEGG module covers this capability. Threonine aldolase is deliberately excluded as a route because it would require L-threonine as an input anchor and adds only 133 KEGG genomes beyond those carrying glyA.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

### `aspartate_semialdehyde_biosynthesis` — Aspartate to aspartate 4-semialdehyde

- **Scope:** `ASPARTATE` → `ASA`; `anabolic` metabolic capability.
- **Why this limit:** Shared head of KEGG M00018 and M00017, cut out so that neither module duplicates it. Anchored at the semialdehyde so the lysine and diaminopimelate branch can attach without re-cutting this GIFT.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

### `homoserine_biosynthesis` — Aspartate 4-semialdehyde to homoserine

- **Scope:** `ASA` → `HOMOSERINE`; `anabolic` metabolic capability.
- **Why this limit:** Single-reaction GIFT shared by KEGG M00018 and M00017. It is not merged into the upstream GIFT because homoserine dehydrogenase is precisely where the lysine branch is left behind.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

### `threonine_biosynthesis` — Homoserine to threonine

- **Scope:** `HOMOSERINE` → `THREONINE`; `anabolic` metabolic capability.
- **Why this limit:** Tail of KEGG M00018; the aspartate-to-homoserine head is curated separately and composed through the homoserine anchor.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

### `methionine_biosynthesis_transsulfuration` — Homoserine and cysteine to methionine

- **Scope:** `HOMOSERINE`, `CYSTEINE` → `METHIONINE`; `anabolic` metabolic capability.
- **Why this limit:** Tail of KEGG M00017. Separated from the sulfhydrylation capability because the two consume different sulfur substrates, and anchors are declared per GIFT rather than per route. L-homocysteine remains internal here because declaring it as an output would create an unsupported composition through the methionine and cysteine cycle.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md); [boundary decision DBC-20260817-HOMOCYSTEINE-INPUT-ONLY](../extdata/database-source/database_changes.tsv).

### `methionine_biosynthesis_sulfhydrylation` — Homoserine and sulfide to methionine

- **Scope:** `HOMOSERINE`, `SULFIDE` → `METHIONINE`; `anabolic` metabolic capability.
- **Why this limit:** Absent from KEGG M00017 although 3910 KEGG genomes complete methionine biosynthesis this way and no other. gifter curation, not a KEGG import.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

### `cysteine_biosynthesis_sulfide` — Serine and sulfide to cysteine

- **Scope:** `SERINE`, `SULFIDE` → `CYSTEINE`; `anabolic` metabolic capability.
- **Why this limit:** Boundaries of KEGG M00021 retained; the sulfide requirement is declared explicitly as an input anchor so the capability can compose with assimilatory sulfate reduction.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

### `cysteine_biosynthesis_homocysteine` — Serine and homocysteine to cysteine

- **Scope:** `SERINE`, `HOMOCYSTEINE` → `CYSTEINE`; `anabolic` metabolic capability.
- **Why this limit:** KEGG M00338 and the cysteine-forming tail of M00609 merged into one capability with two routes; their enzyme sets share no KEGG genome, which makes them alternatives rather than separate traits. The four SAM-cycle steps of M00609 are excluded.
- **Record:** curation record: [proposal-amino-acid-biosynthesis.md](proposal-amino-acid-biosynthesis.md).

## Curation proposal: complex polysaccharide and sugar degradation GIFTs

Primary reasoning record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `xylose_degradation_isomerase` — D-xylose to D-xylulose 5-phosphate

- **Scope:** `XYLOSE_IN` → `XYLULOSE_5P`; `catabolic` metabolic capability.
- **Why this limit:** No KEGG module covers this capability. The oxidative Weimberg and Dahms routes end at different central metabolites and are therefore different capabilities, not alternative routes of this one.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `arabinose_degradation` — L-arabinose to D-xylulose 5-phosphate

- **Scope:** `ARABINOSE_IN` → `XYLULOSE_5P`; `catabolic` metabolic capability.
- **Why this limit:** Convergence on D-xylulose 5-phosphate is why arabinofuranosidase side-chain release composes with this GIFT rather than needing its own downstream chemistry.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `fucose_degradation_isomerase` — L-fucose to dihydroxyacetone phosphate and (S)-lactaldehyde

- **Scope:** `FUCOSE` → `DHAP`, `LACTALDEHYDE`; `catabolic` metabolic capability.
- **Why this limit:** The oxidative dehydrogenase route yields different products and is a separate capability. Anchors are declared per GIFT, so the two cannot be routes of one trait.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `rhamnose_degradation` — L-rhamnose to dihydroxyacetone phosphate and (S)-lactaldehyde

- **Scope:** `RHAMNOSE` → `DHAP`, `LACTALDEHYDE`; `catabolic` metabolic capability.
- **Why this limit:** Shares product anchors with fucose degradation but no reactions; the two isomerase, kinase and aldolase families are non-homologous.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `galactose_degradation_leloir` — beta-D-galactose to alpha-D-glucose 1-phosphate

- **Scope:** `GALACTOSE` → `GLUCOSE_1P`; `catabolic` metabolic capability.
- **Why this limit:** Boundaries of KEGG M00632 retained. Aldose 1-epimerase is optional because mutarotation also proceeds spontaneously; UDP-glucose 4-epimerase is required because without it the pathway cannot turn over catalytically.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `glcnac_degradation` — N-acetyl-D-glucosamine to beta-D-fructose 6-phosphate

- **Scope:** `GLCNAC` → `FRUCTOSE_6P`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** Ends at fructose 6-phosphate, the point at which amino sugar carbon becomes indistinguishable from glycolytic carbon. Two curated routes differ only in how the cell reaches N-acetylglucosamine 6-phosphate: a cytoplasmic ATP-dependent kinase, or the phosphoenolpyruvate-dependent PTS that phosphorylates the sugar during transport. The input anchor stays N-acetylglucosamine and stays compartment-unspecified, because the two entries genuinely start in different compartments -- the PTS substrate is outside the cell, while the kinase also serves N-acetylglucosamine recovered from the organism's own peptidoglycan inside it.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `neuac_degradation` — N-acetylneuraminate to beta-D-fructose 6-phosphate

- **Scope:** `NEUAC` → `FRUCTOSE_6P`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** Shares the deacetylase and deaminase reactions with GlcNAc degradation but is not a composite of it: the shared intermediate is N-acetyl-D-glucosamine 6-phosphate, which is internal to both and is deliberately not an anchor.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `galacturonate_degradation` — D-galacturonate to 2-dehydro-3-deoxy-D-gluconate

- **Scope:** `GALACTURONATE` → `KDG`; `catabolic` metabolic capability.
- **Why this limit:** Re-cut at 2-dehydro-3-deoxy-D-gluconate in release 2026.21.3. The final two reactions were shared verbatim with glucuronate_degradation and are now kdg_degradation; what remains is the uronate-specific head, which the previous note already said was what the capability is about.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md); [re-cut decision DBC-20260821-KDG-ANCHOR](../extdata/database-source/database_changes.tsv).

### `glucuronate_degradation` — D-glucuronate to 2-dehydro-3-deoxy-D-gluconate

- **Scope:** `GLUCURONATE` → `KDG`; `catabolic` metabolic capability.
- **Why this limit:** Re-cut at 2-dehydro-3-deoxy-D-gluconate in release 2026.21.3, so the boundaries are no longer those of KEGG M00061; the cross-reference is downgraded to subset_of.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md); [re-cut decision DBC-20260821-KDG-ANCHOR](../extdata/database-source/database_changes.tsv).

### `xylose_uptake_abc` — D-xylose uptake

- **Scope:** `XYLOSE_EX` → `XYLOSE_IN`; `transport` metabolic capability.
- **Why this limit:** Curated because D-xylose has both substrate-specific transporter markers and a Rhea master for the translocation. Sugars moved mainly by promiscuous carriers are deliberately left without an uptake GIFT.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `arabinose_uptake_abc` — L-arabinose uptake

- **Scope:** `ARABINOSE_EX` → `ARABINOSE_IN`; `transport` metabolic capability.
- **Why this limit:** As for xylose. The dual-specificity XacGHI system is accepted for both pentoses because it is characterised on both.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `xylan_degradation` — Xylan to D-xylose

- **Scope:** `XYLAN` → `XYLOSE_EX`; `catabolic` metabolic capability.
- **Why this limit:** Endo- and exo-acting chemistry are both required for this curated saccharification capability. Endo-1,4-beta-xylanase depolymerises the xylan backbone and generates additional chain ends and xylo-oligosaccharides, while beta-xylosidase releases D-xylose successively from non-reducing termini. Although beta-xylosidase can in principle release xylose directly from xylan termini, exo activity alone is not treated here as sufficient evidence for complete polymer saccharification. Xylo-oligosaccharide is an internal intermediate, not an anchor: it would become one only if an oligosaccharide importer could be evidenced, which would make the selfish-foraging route independently meaningful.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `arabinoxylan_debranching` — Arabinoxylan to xylan and L-arabinose

- **Scope:** `ARABINOXYLAN` → `XYLAN`, `ARABINOSE_EX`; `catabolic` metabolic capability.
- **Why this limit:** Kept separate from xylan degradation because L-arabinose is itself an anchored fermentable sugar, so the same arabinose GIFTs serve arabinoxylan, arabinan and arabinogalactan without triplicate curation. One reaction, but a complete capability with its own product.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `starch_degradation` — Starch to D-glucose

- **Scope:** `STARCH` → `GLUCOSE`; `catabolic` metabolic capability.
- **Why this limit:** Endo- and exo-acting chemistry are both required for this curated saccharification capability. Alpha-amylase depolymerises the alpha-1,4-glucan backbone and generates additional chain ends and malto-oligosaccharides, while alpha-glucosidase releases D-glucose successively from non-reducing termini. As for xylan, the exo-acting enzyme can in principle act on polymer termini directly, but exo activity alone is not treated here as sufficient evidence for complete polymer saccharification. Debranching is accessory rather than required: amylose carries no alpha-1,6 branch points, so a genome without pullulanase still degrades starch, less completely. Malto-oligosaccharide is an internal intermediate for the same reason as xylo-oligosaccharide.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `chitin_degradation` — Chitin to N-acetyl-D-glucosamine

- **Scope:** `CHITIN` → `GLCNAC`; `catabolic` metabolic capability.
- **Why this limit:** The output is free N-acetyl-D-glucosamine, so endo-acting backbone cleavage and exo-acting monosaccharide release are both required. Ending at the free sugar also allows composition with the separately curated GlcNAc degradation GIFT.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `mucin_sialic_acid_release` — Mucin O-glycan to N-acetylneuraminate

- **Scope:** `MUCIN_O_GLYCAN` → `NEUAC`; `catabolic` metabolic capability.
- **Why this limit:** Curated as a parallel monosaccharide-release capability from one polymer anchor: mucin has no polymer-to-oligomer cut, so the tier model does not apply and each exo-glycosidase is its own trait.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `mucin_fucose_release` — Mucin O-glycan to L-fucose

- **Scope:** `MUCIN_O_GLYCAN` → `FUCOSE`; `catabolic` metabolic capability.
- **Why this limit:** Curated as a parallel monosaccharide-release capability from one polymer anchor: mucin has no polymer-to-oligomer cut, so the tier model does not apply and each exo-glycosidase is its own trait.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `mucin_galnac_release` — Mucin O-glycan to N-acetyl-D-galactosamine

- **Scope:** `MUCIN_O_GLYCAN` → `GALNAC`; `catabolic` metabolic capability.
- **Why this limit:** Curated as a parallel monosaccharide-release capability from one polymer anchor: mucin has no polymer-to-oligomer cut, so the tier model does not apply and each exo-glycosidase is its own trait.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `pectin_degradation` — Pectin to D-galacturonate

- **Scope:** `PECTIN` → `GALACTURONATE`; `catabolic` metabolic capability.
- **Why this limit:** Curated on the hydrolytic chemistry only. The lyase chemistry is a separate capability, pectate_lyase_degradation, because beta-elimination and hydrolysis end at different metabolites and anchors are declared per GIFT.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

### `kdg_degradation` — 2-dehydro-3-deoxy-D-gluconate to pyruvate and D-glyceraldehyde 3-phosphate

- **Scope:** `KDG` → `PYRUVATE`, `GAP`; `catabolic` metabolic capability.
- **Why this limit:** Cut out of galacturonate_degradation and glucuronate_degradation in release 2026.21.3, where the same two reactions were carried twice. KdgK and Eda are also the enzymes of the Entner-Doudoroff pathway proper and of gluconate and alginate catabolism, so the segment is carried by genomes that have no hexuronate head at all.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md); [re-cut decision DBC-20260821-KDG-ANCHOR](../extdata/database-source/database_changes.tsv).

### `pectate_lyase_degradation` — Pectin to 2-dehydro-3-deoxy-D-gluconate by beta-elimination

- **Scope:** `PECTIN` → `KDG`; `catabolic` metabolic capability.
- **Why this limit:** The route runs past the polymer boundary to a monomeric anchor because beta-elimination yields unsaturated oligogalacturonides, which are not promoted to anchors. Oligogalacturonide lyase, the ketol isomerase and the 5-dehydrogenase have no other substrate in the database, so folding them in follows the granularity rule rather than excepting it. The exo-lyase step is required chemistry but its marker support is the thinnest in the route, which makes the call conservative.
- **Record:** curation record: [proposal-polysaccharide-degradation.md](proposal-polysaccharide-degradation.md).

## Curation proposal: protein degradation GIFTs

Primary reasoning record: [proposal-protein-degradation.md](proposal-protein-degradation.md).

### `collagen_cleavage` — Collagen to collagen peptides

- **Scope:** `COLLAGEN` → `COLLAGEN_PEPTIDES`; `catabolic` metabolic capability.
- **Why this limit:** One required reaction, but a complete capability with its own product, as for arabinoxylan debranching. Substrate specificity rests on mechanism rather than on a family name: EC 3.4.24.3 is defined by digestion of native collagen in the triple-helical region, which generic endopeptidases cannot perform because the intact helix resists them. Broadly proteolytic enzymes such as pseudolysin are deliberately excluded even though they hydrolyse collagen among other host proteins, because accepting them would equate this trait with generic proteolysis. The product anchor is substrate-specific rather than a shared peptide pool; a shared oligopeptide tier and peptide uptake are deferred behind transporter evidence.
- **Record:** curation record: [proposal-protein-degradation.md](proposal-protein-degradation.md).

## Structural GIFTs: curated content, refusals, and open questions

Primary reasoning record: [proposal-structural-gifts.md](proposal-structural-gifts.md).

### `flagellar_apparatus` — Flagellar apparatus

- **Scope:** Encodes the structural and assembly machinery of a bacterial flagellum: the type III export apparatus, basal body, C ring, hook, filament and stator of at least one curated flagellar architecture. A positive call means the genome encodes that machinery. It does not mean the organism is motile, that the flagellum is expressed, or that it rotates under any particular condition. (`structural` machinery capability.)
- **Why this limit:** Ion coupling is deliberately not claimed. KEGG assigns the sodium-driven PomA/PomB stator of Vibrio cholerae to K02556/K02557, the same orthologues as the proton-driven MotA/MotB stator of Escherichia coli, so KO evidence cannot separate proton- from sodium-driven motors. Separate proton_driven_flagellar_apparatus and sodium_driven_flagellar_apparatus GIFTs are therefore refused at this evidence level; see inst/doc/proposal-structural-gifts.md. Transcriptional regulators (FlhDC, FliA, FlgM) are excluded because they are regulatory, not structural.
- **Record:** curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md).

### `type_iva_pilus` — Type IVa pilus machinery

- **Scope:** Encodes the machinery required to assemble a type IVa pilus: prepilin processing, a major pilin, an extension ATPase, the inner membrane platform, the PilMNOP alignment subcomplex and the PilQ secretin. A positive call means the genome encodes that machinery; it does not establish twitching motility, natural competence, or adhesion to any particular surface, none of which follow from the assembly machinery alone. (`structural` machinery capability.)
- **Why this limit:** Scoped to the type IVa system because the alignment subcomplex markers (PilM/N/O/P) are specific to it; type IVb and Tad pili are different architectures and are not covered. Retraction is curated as an accessory function: a pilus can be assembled without PilT.
- **Record:** curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md).

### `lpt_lipopolysaccharide_export_apparatus` — Lpt lipopolysaccharide export apparatus

- **Scope:** Encodes one complete curated Lpt machine capable of extracting lipopolysaccharide from the inner membrane, conducting it across the periplasm and inserting it into the outer leaflet of the outer membrane. A positive call means the canonical LptA--G apparatus is encoded; it does not mean lipopolysaccharide is synthesized, expressed or transported in a sampled condition, and it makes no permeability, viability or other phenotypic claim. (`structural` machinery capability.)
- **Why this limit:** The canonical architecture requires LptB/C/F/G, LptA and LptD/E. MsbA, BAM, LptM and YedD are outside this claim. LptC-bypass suppressors depend on residue-level LptF evidence that the accepted markers cannot resolve. An LptE-independent architecture reported in Neisseria meningitidis is not generalized to all LptD proteins and remains an explicit under-call until discriminating evidence can encode that biological context.
- **Record:** curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md).

### `ribitol_phosphate_wall_teichoic_acid` — Poly(ribitol-phosphate) wall teichoic acid

- **Scope:** Encodes one complete curated architecture for building a poly(ribitol-phosphate) wall teichoic acid backbone, exporting it and attaching it to peptidoglycan. A positive call means either the Staphylococcus-type TarF/TarL design or the Bacillus subtilis W23-type TarK/TarL design is encoded; it does not mean the polymer is expressed, decorated, abundant or assembled in a sampled condition, and it makes no resistance, virulence or other phenotypic claim. (`structural` machinery capability.)
- **Why this limit:** Both architectures require UDP-ManNAc supply, TagO/TagA/TagB linkage-unit construction, TagD-dependent CDP-glycerol supply, TarI/TarJ-dependent CDP-ribitol supply, TagG/TagH export and an LCP-family attachment enzyme. They differ only at the chemistry-specific priming and elongation function. The Staphylococcus architecture requires equivalog-grade NCBIfam TarF and TarL evidence; the W23 architecture requires the separate TarK and TarL orthologies. Both were admitted below the standing prevalence threshold by an explicit biological-importance decision. The 168-type glycerol-phosphate architecture remains excluded because no admitted marker distinguishes its TagF polymerase from the W23 non-WTA homologue.
- **Record:** curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md); analysis script: [wta_ncbifam_prevalence.R](../../data-raw/wta_ncbifam_prevalence.R); result table: [wta-ncbifam-prevalence.tsv](../../data-raw/reference/wta-ncbifam-prevalence.tsv).

### `diglucosyl_diacylglycerol_anchored_lipoteichoic_acid` — Diglucosyldiacylglycerol-anchored poly(glycerol-phosphate) lipoteichoic acid

- **Scope:** Encodes a complete curated architecture for synthesizing the diglucosyldiacylglycerol anchor, translocating it across the cytoplasmic membrane and polymerizing a membrane-anchored poly(glycerol-phosphate) lipoteichoic acid chain. A positive call means those three encoded functions are supported; it does not mean the polymer is expressed, decorated, abundant or assembled in a sampled condition, and it makes no envelope-integrity, antibiotic-susceptibility, virulence or other phenotypic claim. (`structural` machinery capability.)
- **Why this limit:** The name is deliberately narrower than lipoteichoic acid or type I lipoteichoic acid. The architecture requires equivalog-grade NCBIfam evidence for the processive YpfP/UgtP-family diglucosyldiacylglycerol synthase, the LtaA anchor flippase and LtaS. K03429 and K19005 are not admitted: the first is retained only as a prevalence proxy and the second spans related glycerophosphotransferase chemistry and cannot resolve primase requirements. Residual diacylglycerol-anchored material after ypfP loss, the Listeria LtaP/LtaS design, Bacillus paralogues, non-type-I LTA and D-alanylation or glycosylation are outside the claim.
- **Record:** curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md); result table: [lta-peptidoglycan-marker-audit.tsv](../../data-raw/reference/lta-peptidoglycan-marker-audit.tsv); result table: [lta-peptidoglycan-prevalence.tsv](../../data-raw/reference/lta-peptidoglycan-prevalence.tsv).

### `type_vi_secretion_apparatus` — Type VI secretion apparatus

- **Scope:** Encodes one complete curated type VI secretion apparatus: the TssL/TssM membrane complex, the TssE/F/G/K baseplate, the VgrG spike, the Hcp inner tube, the TssB/TssC contractile sheath, the TssA assembly coordinator and the ClpV sheath-recycling ATPase. A positive call means that machinery is encoded. It does not mean the apparatus is expressed or fires, it does not identify any effector, immunity protein or target, and it makes no claim of interbacterial antagonism, virulence or any other phenotype. (`structural` machinery capability.)
- **Why this limit:** The single curated architecture is the canonical proteobacterial-type apparatus (T6SS-i). The Francisella-type (T6SS-ii) and Bacteroidota-type (T6SS-iii) apparatuses use divergent components that the accepted markers do not reach, and are explicit under-calls rather than negatives. The TssJ lipoprotein is recorded as an accessory function because reference genomes with an experimentally active apparatus carry no TssJ marker in either namespace. PAAR tip proteins, effectors, immunity proteins, adaptors and regulators are outside the claim. Completeness is evaluated over the unordered marker set, so the call does not assert that the components lie in one locus.
- **Record:** curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md); analysis script: [secretion_system_prevalence.R](../../data-raw/secretion_system_prevalence.R); result table: [secretion-system-controls.tsv](../../data-raw/reference/secretion-system-controls.tsv); result table: [secretion-system-marker-audit.tsv](../../data-raw/reference/secretion-system-marker-audit.tsv); result table: [secretion-system-prevalence.tsv](../../data-raw/reference/secretion-system-prevalence.tsv); result table: [secretion-system-roles.tsv](../../data-raw/reference/secretion-system-roles.tsv).

### `type_iii_secretion_injectisome` — Type III secretion injectisome

- **Scope:** Encodes one complete curated non-flagellar type III secretion apparatus: the SctR/S/T/U/V export apparatus, the SctN export ATPase, the SctD/SctJ inner-membrane rings, the SctC outer-membrane secretin, the SctQ sorting-platform protein, the SctI inner rod and either a needle filament or an Hrp pilus. A positive call means that machinery is encoded. It does not mean the injectisome is expressed or assembled, it does not identify any translocon, effector or host, and it makes no claim of virulence, symbiosis or any other phenotype. (`structural` machinery capability.)
- **Why this limit:** The injectisome is a separate GIFT from flagellar_apparatus: every accepted marker is specific to the non-flagellar system, so flagellar export evidence cannot support this call and injectisome evidence cannot support the flagellum. The SctL stator is biologically required and is deliberately not a required component, because no accepted marker reaches the Inv-Mxi-Spa and Esc families and requiring it would report an absent machine in Shigella and enteropathogenic Escherichia coli. Translocon and needle-tip proteins, gatekeepers, the needle-length ruler, pilotins, chaperones and effectors are outside the claim. Chlamydial and rhizobial injectisomes and Hrp pili without an accepted pilin marker are explicit under-calls. Completeness is evaluated over the unordered marker set, so the call does not assert that the components lie in one locus.
- **Record:** curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md); analysis script: [secretion_system_prevalence.R](../../data-raw/secretion_system_prevalence.R); result table: [secretion-system-controls.tsv](../../data-raw/reference/secretion-system-controls.tsv); result table: [secretion-system-marker-audit.tsv](../../data-raw/reference/secretion-system-marker-audit.tsv); result table: [secretion-system-prevalence.tsv](../../data-raw/reference/secretion-system-prevalence.tsv); result table: [secretion-system-roles.tsv](../../data-raw/reference/secretion-system-roles.tsv).

### `archaellum` — Archaellum machinery

- **Scope:** Encodes the machinery required to assemble an archaellum, the rotary type IV filament motility structure of archaea: the archaellin filament subunit, a class III signal peptidase that processes it, the FlaF/FlaG stator complex, the FlaI motor ATPase with its FlaH regulator, and the FlaJ membrane platform. A positive call means the genome encodes that machinery. It does not mean the organism swims, that archaella are expressed or assembled, that they rotate in either direction, or that the cell performs taxis. (`structural` machinery capability.)
- **Why this limit:** Gene names follow the fla designations that KEGG uses; the arl designations (ArlB, ArlF, ArlG, ArlH, ArlI, ArlJ, ArlK) were proposed in PMID 29912330. The FlaI (K07332) and FlaJ (K07333) orthologies also collect the ATPases and platforms of archaeal type IV pili and the bindosome: in the 470-archaeon frame only 268 of 885 K07332 proteins in archaellum-encoding genomes pass the FlaI equivalog, so both KOs are accepted at putative confidence and the specificity of the call rests on archaellin, FlaF, FlaG and FlaH. No combination of FlaI, FlaJ and the peptidase fires the GIFT. The euryarchaeal FlaC/D/E switch complex and the crenarchaeal FlaX ring are lineage-restricted and are curated as accessory functions; see inst/doc/proposal-structural-gifts.md section 6.1.
- **Record:** curation record: [deferral-register.md](deferral-register.md); curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md); analysis script: [archaellum_ncbifam_prevalence.R](../../data-raw/archaellum_ncbifam_prevalence.R); result table: [archaellum-accessory.tsv](../../data-raw/reference/archaellum-accessory.tsv); result table: [archaellum-controls.tsv](../../data-raw/reference/archaellum-controls.tsv); result table: [archaellum-ko-ncbifam-agreement.tsv](../../data-raw/reference/archaellum-ko-ncbifam-agreement.tsv); result table: [archaellum-ncbifam-profiles.tsv](../../data-raw/reference/archaellum-ncbifam-profiles.tsv); result table: [archaellum-one-short.tsv](../../data-raw/reference/archaellum-one-short.tsv); result table: [archaellum-prevalence.tsv](../../data-raw/reference/archaellum-prevalence.tsv); result table: [archaellum-role-agreement.tsv](../../data-raw/reference/archaellum-role-agreement.tsv).

### `type_ii_secretion_system` — Type II secretion system

- **Scope:** Encodes one complete curated type II secretion apparatus: the GspD outer-membrane secretin, the GspC/F/L/M inner-membrane platform, the GspE secretion ATPase, the GspG/H/I/J/K pseudopilus and the class III prepilin peptidase that processes its pseudopilins. A positive call means that machinery is encoded. It does not identify any secreted substrate, and it does not mean the apparatus is expressed, assembled or secreting, nor that the organism degrades any polymer, colonises a host or is virulent. (`structural` machinery capability.)
- **Why this limit:** The prepilin peptidase is a shared component, not a discriminator: one enzyme processes both type IVa pilins and type II pseudopilins, and KEGG files most of them under PilD (K02654) rather than GspO (K02464). It is therefore accepted on this GIFT and on type_iva_pilus, and it contributes no specificity to either; 1,319 of the 1,536 complete genomes in the reference frame reach the role through PilD alone. The apparatus is nonetheless distinguishable from the pilus by its other four functions: 703 frame genomes complete this architecture without completing the type IVa pilus. GspC is required although its markers are the weakest in the inventory, missing in 335 of the 504 genomes that are one function short; those misses are spread over 108 genera rather than blinding whole clades, so they under-call individual genomes rather than excluding a lineage. The GspS pilotin, GspN, GspAB and secreted substrates are outside the claim.
- **Record:** curation record: [architecture.md](architecture.md); curation record: [proposal-structural-gifts.md](proposal-structural-gifts.md); analysis script: [t2ss_prevalence.R](../../data-raw/t2ss_prevalence.R); result table: [t2ss-controls.tsv](../../data-raw/reference/t2ss-controls.tsv); result table: [t2ss-prevalence.tsv](../../data-raw/reference/t2ss-prevalence.tsv); result table: [t2ss-roles.tsv](../../data-raw/reference/t2ss-roles.tsv).

## Regulatory GIFTs: curated content, refusals, and open questions

Primary reasoning record: [proposal-regulatory-gifts.md](proposal-regulatory-gifts.md).

### `chemotaxis_signal_transduction` — Chemotaxis signal transduction

- **Scope:** Encodes the core chemotaxis signal-transduction machinery: a chemoreceptor, the CheA histidine kinase with its CheW coupling protein, the CheY response regulator, and the CheR/CheB adaptation cycle. A positive call means the genome encodes that pathway. It does not mean the cell is chemotactic, that the pathway is expressed, or that the organism responds to any particular compound: which chemoeffectors are detected depends on receptor sensing domains this claim says nothing about. (`regulatory` machinery capability.)
- **Why this limit:** The reception function accepts either a generic methyl-accepting chemotaxis protein (K03406) or any characterised chemoreceptor. Both are needed: Escherichia coli K-12 carries no K03406 orthologue at all, its four receptors being assigned to the characterised groups, while Pseudomonas aeruginosa carries 21 K03406 genes and Vibrio cholerae 34. Signal termination is accessory and has three non-homologous implementations (CheZ, CheC, CheX). CheV is not accepted as a CheW substitute. See inst/doc/proposal-regulatory-gifts.md.
- **Record:** curation record: [proposal-regulatory-gifts.md](proposal-regulatory-gifts.md); curation record: [proposal-regulatory-defense-expansion.md](proposal-regulatory-defense-expansion.md).

### `aspartate_chemoreception` — Aspartate chemoreception

- **Scope:** Encodes the machinery to detect L-aspartate and transduce it into the chemotaxis pathway: the Tar aspartate chemoreceptor together with the shared chemotaxis kinase, response-regulator and adaptation functions. A positive call means the genome encodes an aspartate-responsive chemosensory input. It does not mean the cell swims toward aspartate, which additionally requires expression, a working flagellar motor, and a gradient. (`regulatory` machinery capability.)
- **Why this limit:** This GIFT exists to keep the core pathway honest. Its reception function accepts K05875 (Tar) only. The generic chemoreceptor accession K03406 is deliberately refused here: it identifies the conserved cytoplasmic signalling domain shared by every chemoreceptor and cannot single out an aspartate sensor, so accepting it would let any chemotactic genome claim aspartate sensing. The three downstream functions are the same curated rows the core circuit uses.
- **Record:** curation record: [proposal-regulatory-gifts.md](proposal-regulatory-gifts.md).

### `phosphate_starvation_response` — Phosphate starvation response

- **Scope:** Encodes a phosphate-starvation two-component regulatory system: the PhoR sensor histidine kinase paired with a cognate phosphate-regulon response regulator. A positive call means the genome encodes the signalling machinery. It does not mean the regulon is induced, that the cell is phosphate-limited, or that any particular gene is regulated. (`regulatory` machinery capability.)
- **Why this limit:** Two curated circuits share the PhoR sensor and differ in the response regulator: PhoB (K07657) in enterobacteria, pseudomonads and vibrios, PhoP (K07658) in Bacillus and relatives. Across the reference genomes checked on 2026-08-18 the sensor is single-copy where present and the two regulator groups are mutually exclusive, which is what licenses orthology as evidence of a cognate pair here. K07660, the response regulator of the magnesium-sensing PhoP/PhoQ system, shares the gene name and is a different protein; it is not accepted. The PstSCAB-PhoU complex is accessory because it is independently a transport capability.
- **Record:** curation record: [proposal-regulatory-gifts.md](proposal-regulatory-gifts.md).

## Defense GIFTs: curated content, refusals, and open questions

Primary reasoning record: [proposal-defense-gifts.md](proposal-defense-gifts.md).

### `type_i_restriction_modification` — Type I restriction-modification

- **Scope:** Encodes a complete type I restriction-modification system: the HsdS specificity subunit, the HsdM methyltransferase that protects the host's own target sites, and the HsdR subunit that translocates and cleaves unmethylated DNA. A positive call means the genome encodes that mechanism. It does not mean the organism resists any particular phage, which depends on the invader's anti-restriction counter-measures and on defences this GIFT does not describe. (`defense` machinery capability.)
- **Why this limit:** All three subunits are required. A genome carrying only HsdM and HsdS has a methylation capability, which is real biology and common as an orphan methyltransferase, but it defends against nothing and is correctly called incomplete here. The target sequence the system recognises is deliberately not claimed: HsdS specificity comes from variable target recognition domains that the orthology group does not resolve.
- **Record:** curation record: [proposal-defense-gifts.md](proposal-defense-gifts.md).

### `type_i_e_crispr_cas_machinery` — Type I-E CRISPR-Cas machinery

- **Scope:** Encodes the protein machinery of a type I-E CRISPR-Cas system: the five-subunit Cascade surveillance complex and the Cas3 nuclease-helicase, with Cas1-Cas2 spacer acquisition accessory. A positive call means the genome encodes those proteins. It does not mean the system can interfere with anything, because interference additionally requires a CRISPR array to supply guide RNAs, and an array is a repeat-spacer locus detected by structure rather than a protein annotation. (`defense` machinery capability.)
- **Why this limit:** The claim is deliberately narrowed to the encoded machinery. gifter's evidence layer is an annotation accession, which cannot express 'a CRISPR array was detected in this genome', and no Cas protein accession is evidence that an array is present. Broadening the evidence model to genomic features was considered and deferred to a second demonstrated need; see inst/doc/proposal-defense-gifts.md.
- **Record:** curation record: [proposal-defense-gifts.md](proposal-defense-gifts.md).

## Curation proposal: short-chain fatty acid formation GIFTs

Primary reasoning record: [proposal-scfa-biosynthesis.md](proposal-scfa-biosynthesis.md).

### `pyruvate_to_acetyl_coa` — Pyruvate to acetyl-CoA

- **Scope:** `PYRUVATE` → `ACETYL_COA`; `catabolic` metabolic capability.
- **Why this limit:** No KEGG module covers this capability as a unit. Three non-homologous routes are curated because they are not interchangeable: the dehydrogenase complex is the aerobic route, the ferredoxin oxidoreductase and formate-lyase routes are oxygen-sensitive, and 10961 of 11856 KEGG organisms complete at least one. The dehydrogenase reaction carries two alternative systems because the fused E1 of Escherichia coli (K00163) and the alpha/beta E1 of Bacillus (K00161 with K00162) are different architectures; requiring either alone would call roughly 4800 genomes negative for chemistry they have.
- **Record:** curation record: [proposal-scfa-biosynthesis.md](proposal-scfa-biosynthesis.md).

### `acetate_interconversion` — Acetyl-CoA and acetate interconversion

- **Scope:** `ACETYL_COA`, `ACETATE` → `ACETATE`, `ACETYL_COA`; `interconversion` metabolic capability.
- **Why this limit:** Declared interconversion rather than catabolic because the node is near-equilibrium and physiologically bidirectional, and because a catabolic declaration would place any future acetate-activation GIFT in a within-mode cycle with this one. Boundaries of KEGG M00579 retained. 6582 of 11856 KEGG organisms complete it, so a positive call carries little discriminating power on its own; it is curated because it is the boundary the butyrate transferase route consumes.
- **Record:** curation record: [proposal-scfa-biosynthesis.md](proposal-scfa-biosynthesis.md).

### `butyrate_formation` — Acetyl-CoA and acetate to butanoate

- **Scope:** `ACETYL_COA`, `ACETATE` → `BUTYRATE`; `catabolic` metabolic capability.
- **Why this limit:** Absent from KEGG, and not curatable from KEGG orthology: the four core enzymes are chain-length-generic and the transferase shares K01034 and K01035 with the acetoacetate degradation transferase of Escherichia coli, so a KO-evidenced route calls Faecalibacterium prausnitzii, Roseburia intestinalis and Agathobacter rectalis negative and Bacillus subtilis positive. The terminal step is therefore evidenced by NCBIfam TIGR03948, corroborated by InterPro IPR023990 and HAMAP MF_03227. The butyrate kinase route is deliberately refused because Ptb and Buk are shared with Bacillus branched-chain acyl-CoA metabolism at KO and at TIGRFAM level alike. See inst/doc/proposal-scfa-biosynthesis.md.
- **Record:** curation record: [proposal-scfa-biosynthesis.md](proposal-scfa-biosynthesis.md).

### `propanediol_formation` — (S)-lactaldehyde to (S)-propane-1,2-diol

- **Scope:** `LACTALDEHYDE` → `PROPANEDIOL`; `catabolic` metabolic capability.
- **Why this limit:** One reaction, but a complete capability with its own product, as for arabinoxylan debranching. Curated separately from the propionate route because propane-1,2-diol is itself a documented boundary metabolite: genomes carrying the propanediol utilisation operon frequently acquire the diol rather than making it, and 87 of the 232 such genomes carry no lactaldehyde reductase at all.
- **Record:** curation record: [proposal-scfa-biosynthesis.md](proposal-scfa-biosynthesis.md).

### `propionate_formation_propanediol` — (S)-propane-1,2-diol to propanoate

- **Scope:** `PROPANEDIOL` → `PROPIONATE`; `catabolic` metabolic capability.
- **Why this limit:** No KEGG module covers this capability. 168 of 11856 KEGG organisms complete it and they are the propanediol utilisation operon of the Enterobacteriaceae: Salmonella (51), Klebsiella (46), Citrobacter (24), Yersinia (18) and Escherichia (9). The dehydratase is adenosylcobalamin-dependent; gifter models no cofactor availability, so the call does not assert that B12 is present.
- **Record:** curation record: [proposal-scfa-biosynthesis.md](proposal-scfa-biosynthesis.md).

### `propionate_formation_acrylate` — (R)-lactate to propanoate

- **Scope:** `LACTATE` → `PROPIONATE`; `catabolic` metabolic capability.
- **Why this limit:** The most substrate-specific and least prevalent capability in this layer. All 13 KEGG organisms carrying propionate CoA-transferase with both lactoyl-CoA dehydratase subunits are characterised acrylate-pathway producers, among them Anaerotignum propionicum, Megasphaera elsdenii and Pseudocoprococcus catus, and no genome outside that group carries the set. The acryloyl-CoA reductase K20143 is assigned in only 4 of those 13, so most are reported incomplete with the reductase named as the missing reaction rather than having the step scored away; this follows the serine phosphatase precedent. The lcdC activator subunit has no orthology group and is not required.
- **Record:** curation record: [proposal-scfa-biosynthesis.md](proposal-scfa-biosynthesis.md).

## Curation proposal: organic acid formation GIFTs

Primary reasoning record: [proposal-organic-acid-formation.md](proposal-organic-acid-formation.md).

### `lactate_formation` — Pyruvate to (S)-lactate

- **Scope:** `PYRUVATE` → `LACTATE_L`; `catabolic` metabolic capability.
- **Why this limit:** The pyruvate-to-(S)-lactate cut separates this product from lactate oxidation and from (R)-lactate, which can be reached through the separately curated racemase. The current route accepts K00016 and excludes quinone- and cytochrome-dependent lactate dehydrogenase groups, following the original KO distribution analysis. This is a genomic chemistry claim, not proof of physiological direction: [RHEA:23444](https://www.rhea-db.org/rhea/23444) is reversible, and [Zhao et al. 2013](https://pubmed.ncbi.nlm.nih.gov/24251099/) observed NAD-dependent lactate oxidation. The [retrospective audit](catalogue-expansion-log.md#retrospective-evidence-audit-2026-10-05) flags the current marker wording for reassessment.
- **Record:** curation record: [proposal-organic-acid-formation.md](proposal-organic-acid-formation.md); retrospective analysis: [catalogue-expansion-log.md](catalogue-expansion-log.md#retrospective-evidence-audit-2026-10-05).

### `lactate_racemisation` — (S)-lactate and (R)-lactate interconversion

- **Scope:** `LACTATE_L`, `LACTATE` → `LACTATE`, `LACTATE_L`; `interconversion` metabolic capability.
- **Why this limit:** Declared interconversion rather than catabolic because a racemase is the purest instance of that mode: acetate_interconversion is reversible as a matter of physiology, LarA as a matter of definition. It resolves a defect the SCFA layer left behind. propionate_formation_acrylate consumes (R)-lactate and nothing produced it, and of the ten KEGG genomes behind that route eight carry K22373 while only two carry a D-lactate dehydrogenase, so the racemase is how those organisms actually reach the anchor.
- **Record:** curation record: [proposal-organic-acid-formation.md](proposal-organic-acid-formation.md).

### `malolactic_fermentation` — (S)-malate to (S)-lactate

- **Scope:** `MALATE` → `LACTATE_L`; `catabolic` metabolic capability.
- **Why this limit:** K22212 is present in 337 organisms and the set is Streptococcus, Lacticaseibacillus, Enterococcus, Lactococcus, Limosilactobacillus, Lactiplantibacillus, Lactobacillus and Leuconostoc almost without exception. The step releases CO2 and is therefore irreversible, which is why malate may be a boundary here while fumarase and malate dehydrogenase license no malate-forming trait.
- **Record:** curation record: [proposal-organic-acid-formation.md](proposal-organic-acid-formation.md).

### `citrate_fermentation` — Citrate to pyruvate and acetate

- **Scope:** `CITRATE` → `ACETATE`, `PYRUVATE`; `catabolic` metabolic capability.
- **Why this limit:** The lyase with its activating ligase is complete in 912 of 11855 organisms and adding an oxaloacetate decarboxylase gives 369, led by Salmonella, Streptococcus, Klebsiella, Lacticaseibacillus and Enterococcus. Bacillus subtilis, Bacteroides thetaiotaomicron and Pseudomonas aeruginosa are negative. Oxaloacetate is an internal intermediate and is deliberately not an anchor. The citrate transporter is not required evidence: Escherichia coli K-12 carries CitT and is aerobically Cit-negative because the gene is not expressed under oxygen, so requiring it would look like a phenotype claim without being one.
- **Record:** curation record: [proposal-organic-acid-formation.md](proposal-organic-acid-formation.md).

### `ethanol_formation` — Acetyl-CoA to ethanol

- **Scope:** `ACETYL_COA` → `ETHANOL`; `catabolic` metabolic capability.
- **Why this limit:** K04072 is present in 2519 organisms, led by Streptococcus, Vibrio, Bacillus, Escherichia, Clostridium and Bifidobacterium. The route deliberately does not cover Zymomonas mobilis or Saccharomyces cerevisiae, which decarboxylate pyruvate through K01568 with a separate alcohol dehydrogenase; that route is complete in 258 organisms, is fungus-dominated, and its bacterial tail is Acetobacter and Gluconobacter, which oxidise ethanol rather than form it. It is left for a later pass rather than curated as an equal alternative.
- **Record:** curation record: [proposal-organic-acid-formation.md](proposal-organic-acid-formation.md).

### `acetoin_formation` — Pyruvate to (R)-acetoin

- **Scope:** `PYRUVATE` → `ACETOIN`; `catabolic` metabolic capability.
- **Why this limit:** K01575 is present in 1649 organisms, led by Streptococcus, Bacillus, Corynebacterium, Staphylococcus, Klebsiella, Enterobacter, Listeria, Enterococcus and Lactococcus. The synthase step is curated but not required, because its orthology group K01652 is the anabolic branched-chain amino acid synthase ilvB/ilvG/ilvI and carries no acetoin-specific information; requiring it changes the call in 50 of 1649 genomes and imports a marker that means something else. Butane-2,3-diol is one step further and is not curated.
- **Record:** curation record: [proposal-organic-acid-formation.md](proposal-organic-acid-formation.md).

## Curation proposal: vitamin biosynthesis GIFTs

Primary reasoning record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `riboflavin_biosynthesis` — GTP and D-ribulose 5-phosphate to riboflavin

- **Scope:** `GTP`, `RIBULOSE_5P` → `RIBOFLAVIN`; `anabolic` metabolic capability.
- **Why this limit:** Boundary ends at riboflavin. The flavin kinase and FMN adenylyltransferase that make FMN and FAD are shared housekeeping, complete in every reference genome including those that cannot make riboflavin, and are deliberately not curated.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `paba_biosynthesis` — Chorismate to 4-aminobenzoate

- **Scope:** `CHORISMATE` → `PABA`; `anabolic` metabolic capability.
- **Why this limit:** Cut from folate biosynthesis because the two halves are separately lost: 4099 KEGG bacteria complete both branches, 1799 only the pterin branch and 989 only this one.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `folate_biosynthesis` — GTP and 4-aminobenzoate to tetrahydrofolate

- **Scope:** `GTP`, `PABA` → `THF`; `anabolic` metabolic capability.
- **Why this limit:** Two dephosphorylation steps between the pterin triphosphate and dihydroneopterin are not gating. The pyrophosphatase is curated as not required because its orthology is Proteobacteria-biased; the residual monophosphatase step is not curated at all, because the only marker offered for it is a generic alkaline phosphatase that would fire in every genome.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `hmp_phosphate_biosynthesis` — AIR to the thiamine pyrimidine

- **Scope:** `AIR` → `HMP_PP`; `anabolic` metabolic capability.
- **Why this limit:** AIR is declared as an input anchor only. Purine core biosynthesis does not declare it as an output, so no composition edge is created from an internal purine intermediate.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `thiazole_phosphate_biosynthesis` — DXP to the thiamine thiazole

- **Scope:** `DXP` → `THZ_P`; `anabolic` metabolic capability.
- **Why this limit:** ThiS and ThiF are not required components. ThiF is homologous to MoeB and ThiI also serves tRNA thiolation, so neither marker adds thiamine specificity, while requiring them would reduce the trait from 5396 to 1554 bacterial genomes.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `thiamine_phosphate_biosynthesis` — Thiamine pyrimidine and thiazole to thiamine phosphate

- **Scope:** `HMP_PP`, `THZ_P` → `TMP`; `anabolic` metabolic capability.
- **Why this limit:** The boundary stops at thiamine phosphate rather than the diphosphate. ThiL is absent from the KEGG annotation of ten of eighteen reference genomes that certainly make TPP, so requiring it would turn an annotation gap into an auxotrophy call.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `thiamine_precursor_salvage` — Thiamine precursor salvage to the activated moieties

- **Scope:** `HMP`, `HET` → `HMP_PP`, `THZ_P`; `anabolic` metabolic capability.
- **Why this limit:** Curated as a separate capability that composes with thiamine phosphate biosynthesis through the HMP_PP and THZ_P anchors, so that ThiE is curated once rather than duplicated into a salvage route.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `pantothenate_biosynthesis` — 2-oxoisovalerate and L-aspartate to pantothenate

- **Scope:** `OXOISOVALERATE`, `ASPARTATE` → `PANTOTHENATE`; `anabolic` metabolic capability.
- **Why this limit:** The boundary stops at pantothenate. The five steps that convert it to coenzyme A are shared housekeeping and are not curated. KEGG M00119 defines completeness without PanC or PanD and therefore never reaches pantothenate.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `plp_biosynthesis_r5p` — Ribose 5-phosphate and glyceraldehyde 3-phosphate to pyridoxal 5-phosphate

- **Scope:** `RIBOSE_5P`, `GLUTAMINE` → `PLP`; `anabolic` metabolic capability.
- **Why this limit:** Separate from the DXP-dependent capability because the input boundaries differ, following the precedent of the two methionine biosynthesis GIFTs. The two routes are near-disjoint across bacteria and together cover 4199 genomes.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `plp_biosynthesis_dxp` — Erythrose 4-phosphate and DXP to pyridoxal 5-phosphate

- **Scope:** `E4P`, `DXP` → `PLP`; `anabolic` metabolic capability.
- **Why this limit:** Shares phosphoserine aminotransferase with serine biosynthesis. The marker is accepted for this reaction, not as evidence of vitamin B6 synthesis on its own; the other five reactions carry the claim.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `biotin_biosynthesis` — Pimeloyl-CoA to biotin

- **Scope:** `PIMELOYL_COA` → `BIOTIN`; `anabolic` metabolic capability.
- **Why this limit:** The precursor supply that makes the pimelate thioester is deliberately not curated: BioC/BioH, BioI, BioW and BioU are non-homologous solutions and no marker set spans them. The thioester carrier is not distinguished by the BioF marker, so the claim covers both the CoA and the acyl-carrier-protein forms.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `quinolinate_biosynthesis_aspartate` — L-aspartate to quinolinate

- **Scope:** `ASPARTATE` → `QUINOLINATE`; `anabolic` metabolic capability.
- **Why this limit:** Cut at quinolinate so that de novo ring formation and pyridine salvage are separate claims that share no reactions.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `namn_biosynthesis_quinolinate` — Quinolinate to nicotinate D-ribonucleotide

- **Scope:** `QUINOLINATE`, `PRPP` → `NAMN`; `anabolic` metabolic capability.
- **Why this limit:** Curated as its own GIFT so that the de novo and salvage capabilities can share the downstream adenylylation and amidation without duplicating them.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `nad_biosynthesis_namn` — Nicotinate D-ribonucleotide to NAD

- **Scope:** `NAMN` → `NAD`; `anabolic` metabolic capability.
- **Why this limit:** Shared by the de novo and salvage capabilities, which is why it is curated once rather than repeated in both.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `namn_salvage_nicotinate` — Nicotinate to nicotinate D-ribonucleotide

- **Scope:** `NICOTINATE`, `PRPP` → `NAMN`; `anabolic` metabolic capability.
- **Why this limit:** The layer separates being able to use vitamin B3 from being able to make it. 6921 KEGG bacteria carry this salvage together with the trunk, against 6398 that can form quinolinate from aspartate.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `corrin_ring_biosynthesis` — Uroporphyrinogen III to cobyrinate a,c-diamide

- **Scope:** `UROGEN_III` → `COBYRINATE_DIAMIDE`; `anabolic` metabolic capability.
- **Why this limit:** Recall is limited by gene fusion: Propionibacterium freudenreichii carries cysG_cbiX and a cobJ_cbiE_cbiG_cbiH fusion that KEGG assigns to none of the component orthology groups, so the industrial B12 producer is called incomplete with three named missing reactions. Pfam PF00590 covers every cobalt-precorrin methyltransferase and cannot resolve the individual steps, so no domain marker rescues it.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `cobinamide_biosynthesis` — Cobyrinate a,c-diamide to adenosylcobinamide phosphate

- **Scope:** `COBYRINATE_DIAMIDE` → `ADENOSYLCOBINAMIDE_P`; `anabolic` metabolic capability.
- **Why this limit:** Curated separately from the ring because the two are separately present: 4428 KEGG bacteria carry this chemistry against 1081 that also complete a corrin ring.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `cobamide_nucleotide_loop_assembly` — Adenosylcobinamide phosphate and dimethylbenzimidazole to cobalamin

- **Scope:** `ADENOSYLCOBINAMIDE_P`, `DMB`, `NAMN` → `COBALAMIN`; `anabolic` metabolic capability.
- **Why this limit:** Declares nicotinate D-ribonucleotide as an input anchor because CobT consumes it, which is what connects the cobamide layer to NAD metabolism. The CobU kinase half of the bifunctional marker is what lets a salvager enter this capability from imported cobinamide.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `dmb_biosynthesis_aerobic` — FMNH2 to 5,6-dimethylbenzimidazole

- **Scope:** `FMNH2` → `DMB`; `anabolic` metabolic capability.
- **Why this limit:** FMNH2 is declared as an input-only anchor. BluB destroys the flavin to build the benzimidazole ring, which is the one case in this layer where a cofactor is a substrate rather than a recycled participant.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

### `menaquinone_biosynthesis` — Chorismate to menaquinone

- **Scope:** `CHORISMATE` → `MENAQUINONE`; `anabolic` metabolic capability.
- **Why this limit:** Two orphan steps are curated as not required: MenH, whose elimination also proceeds without a dedicated enzyme, and the DHNA-CoA thioesterase, which has several non-homologous replacements and no orthology group covering them. Requiring both would reduce the classical route from 3109 to 1355 bacterial genomes.
- **Record:** curation record: [proposal-vitamin-biosynthesis.md](proposal-vitamin-biosynthesis.md).

## Design proposal: circular central metabolism and higher-order metabolic topology

Primary reasoning record: [proposal-central-metabolic-cycles.md](proposal-central-metabolic-cycles.md).

### `acetyl_coa_to_isocitrate` — Acetyl-CoA and oxaloacetate to isocitrate

- **Scope:** `ACETYL_COA`, `OXALOACETATE` → `ISOCITRATE`; `catabolic` metabolic capability.
- **Why this limit:** Re-cut from acetyl_coa_to_oxoglutarate so that the oxidative and glyoxylate branches do not duplicate citrate synthase and aconitase. K01659 remains accepted at ambiguous confidence because it contains genuine citrate synthases as well as 2-methylcitrate synthases. K01681, K01682 and K27802 remain alternative aconitase markers. Full assessment in inst/doc/proposal-central-metabolic-cycles.md.
- **Record:** curation record: [proposal-central-metabolic-cycles.md](proposal-central-metabolic-cycles.md).

### `oxoglutarate_to_succinate` — 2-oxoglutarate to succinate

- **Scope:** `OXOGLUTARATE` → `SUCCINATE`; `catabolic` metabolic capability.
- **Why this limit:** The dehydrogenase complex is complete in 6902 organisms, the ferredoxin oxidoreductase in 3288 and the decarboxylase bypass in 1420; 8932 complete at least one. The bypass is the actinobacterial substitution that makes Mycobacterium tuberculosis and Corynebacterium glutamicum positive although both lack the E1o component. Direction is claimed for the GIFT as a whole and is honest for the dehydrogenase and decarboxylase routes, both of which release CO2 irreversibly; the ferredoxin route is the reductive citric acid cycle enzyme and is genuinely reversible, so its direction is a route-level claim the markers do not independently support. Making mode route-scoped is recorded as open question Q2 of inst/doc/proposal-central-metabolic-cycles.md. Succinyl-CoA synthetase is curated as one reaction with two enzyme systems rather than as separate ADP- and GDP-forming reactions, because K01899 and K01900 carry both EC numbers and no marker separates them.
- **Record:** curation record: [proposal-central-metabolic-cycles.md](proposal-central-metabolic-cycles.md).

### `succinate_fumarate_interconversion` — Succinate and fumarate interconversion

- **Scope:** `SUCCINATE`, `FUMARATE` → `SUCCINATE`, `FUMARATE`; `interconversion` metabolic capability.
- **Why this limit:** K00239 is named by KEGG sdhA, frdA and K00240 sdhB, frdB: one group for both enzymes, present in 8047 organisms. The dedicated frdAB group K00244/K00245 exists in 1059, almost all Enterobacteriaceae, and 943 of the 1041 genomes carrying frdABCD also carry sdhABCD, so the split is a paralogue duplication within one clade rather than a functional partition. Two opposed directional GIFTs would therefore be complete on identical markers in 8047 genomes. Only the catalytic flavoprotein and iron-sulfur subunits are required; requiring the cytochrome b anchor K00241 as well would call a further 402 genomes negative on a poorly conserved membrane subunit. The generic quinone reaction RHEA:40523 is curated rather than the ubiquinone, menaquinone or rhodoquinone forms, because no marker distinguishes them; resolving that is the trigger recorded for splitting this GIFT.
- **Record:** curation record: [proposal-central-metabolic-cycles.md](proposal-central-metabolic-cycles.md).

### `fumarate_oxaloacetate_interconversion` — Fumarate and oxaloacetate interconversion

- **Scope:** `FUMARATE`, `OXALOACETATE` → `FUMARATE`, `OXALOACETATE`; `interconversion` metabolic capability.
- **Why this limit:** Fumarase is present in 10618 organisms and malate dehydrogenase or malate:quinone oxidoreductase in 9752; 9533 carry both. Rhea writes RHEA:12460 as (S)-malate = fumarate + H2O, so the traversal curated here records the hydratase step as reverse. Only malate:quinone oxidoreductase is effectively unidirectional towards oxaloacetate and it is one alternative system out of four, which is why the GIFT as a whole may not claim a direction. Splitting this GIFT at malate was assessed and deferred until a better-evidenced malate producer exists; see open question Q5 of inst/doc/proposal-central-metabolic-cycles.md.
- **Record:** curation record: [proposal-central-metabolic-cycles.md](proposal-central-metabolic-cycles.md).

### `isocitrate_to_oxoglutarate` — Isocitrate to 2-oxoglutarate

- **Scope:** `ISOCITRATE` → `OXOGLUTARATE`; `catabolic` metabolic capability.
- **Why this limit:** Separated from acetyl_coa_to_isocitrate so that the glyoxylate bypass can branch at a declared anchor without duplicating the upper segment. The two cofactor-specific reactions are alternative routes because their markers distinguish them.
- **Record:** curation record: [proposal-central-metabolic-cycles.md](proposal-central-metabolic-cycles.md).

## Curation proposal: shikimate-derived aromatic biosynthesis

Primary reasoning record: [proposal-shikimate-aromatics.md](proposal-shikimate-aromatics.md).

### `chorismate_biosynthesis` — Phosphoenolpyruvate and erythrose 4-phosphate to chorismate

- **Scope:** `PEP`, `E4P` → `CHORISMATE`; `anabolic` metabolic capability.
- **Why this limit:** Boundaries chosen independently of KEGG M00022, which shares them. The archaeal route to 3-dehydroquinate from 6-deoxy-5-ketofructose 1-phosphate and aspartate semialdehyde is deliberately outside this GIFT: it consumes different precursors, so it cannot be a route between these anchors.
- **Record:** curation record: [proposal-shikimate-aromatics.md](proposal-shikimate-aromatics.md).

### `salicylate_biosynthesis` — Chorismate to salicylate

- **Scope:** `CHORISMATE` → `SALICYLATE`; `anabolic` metabolic capability.
- **Why this limit:** One route of two reactions. PchA/PchB and the bifunctional salicylate synthases MbtI, Irp9 and YbtS run the same two transformations, so they are curated as alternative enzyme systems rather than as alternative routes.
- **Record:** curation record: [proposal-shikimate-aromatics.md](proposal-shikimate-aromatics.md).

### `indole_3_acetate_biosynthesis` — L-tryptophan to indole-3-acetate

- **Scope:** `TRYPTOPHAN` → `INDOLE_3_ACETATE`; `anabolic` metabolic capability.
- **Why this limit:** Only the IAM route is curated. The indole-3-pyruvate, tryptamine, indole-3-acetonitrile and tryptophan side-chain oxidase routes are refused for want of markers that discriminate the activity; see inst/doc/proposal-shikimate-aromatics.md.
- **Record:** curation record: [proposal-shikimate-aromatics.md](proposal-shikimate-aromatics.md).

## Curation proposal: nitrogen compound catabolism GIFTs

Primary reasoning record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `urate_degradation` — Urate to allantoin

- **Scope:** `URATE` → `ALLANTOIN`; `catabolic` metabolic capability.
- **Why this limit:** Allantoin is a separately usable intermediate: the original bacterial screen found many genomes with urate ring-opening markers but no allantoin degradation, and many allantoin consumers without uricase. Ending here keeps those encoded capabilities distinct; ammonium release additionally needs allantoin degradation and urea hydrolysis.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `allantoin_degradation` — Allantoin to glyoxylate and urea

- **Scope:** `ALLANTOIN` → `GLYOXYLATE`, `UREA`; `catabolic` metabolic capability.
- **Why this limit:** Route-specific nitrogen fate: the deiminase route additionally releases two ammonium, the allantoicase route none. AMMONIUM is therefore not a declared output, because a GIFT anchor must hold for every route.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `urea_hydrolysis` — Urea to ammonium

- **Scope:** `UREA` → `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** The UreD, UreE, UreF and UreG maturation proteins are deliberately not curated as components of the catalytic system. They perform nickel insertion rather than catalysis, and requiring all four drops the capability from 3725 to 2741 bacteria.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `nitrate_assimilation` — Nitrate to ammonium

- **Scope:** `NITRATE` → `AMMONIUM`; `anabolic` metabolic capability.
- **Why this limit:** Mode is anabolic on the SULFIDE precedent: assimilable inorganic nutrients enter gifter as inputs to anabolic capabilities. A fifth assimilatory mode was considered and deferred.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `betaine_demethylation` — Glycine betaine to sarcosine

- **Scope:** `BETAINE` → `SARCOSINE`; `catabolic` metabolic capability.
- **Why this limit:** Every curated route is aerobic, because the first step is a Rieske monooxygenase that consumes molecular oxygen. A positive call means that chemistry is encoded; the anaerobic betaine reductase route to trimethylamine is a different capability and is not curated.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `sarcosine_demethylation` — Sarcosine to glycine

- **Scope:** `SARCOSINE` → `GLYCINE`; `catabolic` metabolic capability.
- **Why this limit:** This is the shared tail of betaine and creatinine catabolism, curated once and reached from both by composition rather than duplicated in either.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `creatinine_degradation` — Creatinine to sarcosine and urea

- **Scope:** `CREATININE` → `SARCOSINE`, `UREA`; `catabolic` metabolic capability.
- **Why this limit:** The creatinine deiminase route is refused: K01485 is a cytosine/creatinine deaminase, one accession for two activities, and the cytosine activity is the common one.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `carnitine_degradation_trimethylamine` — L-carnitine to trimethylamine

- **Scope:** `CARNITINE` → `TRIMETHYLAMINE`; `catabolic` metabolic capability.
- **Why this limit:** The current definition accepts the CntAB monooxygenase route that releases free trimethylamine. The proposed carnitine dehydrogenase route was separated after Rhea chemistry showed that it reaches glycine betaine without releasing free trimethylamine. The Cai operon yields γ-butyrobetaine and is outside both GIFTs. A call makes no claim about actual trimethylamine release or host conversion to trimethylamine N-oxide.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md); [corrected product decision DBC-20260818-CARNITINE-SPLIT](../extdata/database-source/database_changes.tsv).

### `carnitine_to_betaine` — L-carnitine to glycine betaine

- **Scope:** `CARNITINE` → `BETAINE`; `catabolic` metabolic capability.
- **Why this limit:** This is a separate product from free trimethylamine: the Cdh route reaches a betainyl thioester and then glycine betaine. The terminal thioesterase is recorded as an accessory step because its only marker, K27497, also carries the first step and requiring it would under-call the route.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md); [corrected product decision DBC-20260818-CARNITINE-SPLIT](../extdata/database-source/database_changes.tsv).

### `methylamine_degradation` — Methylamine to ammonium

- **Scope:** `METHYLAMINE` → `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** The N-methylglutamate route is deferred: its four jointly required subunits complete in 46 bacteria, where single missing annotations would dominate the call.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `taurine_desulfonation_aerobic` — Taurine to sulfite

- **Scope:** `TAURINE_IN` → `SULFITE`; `catabolic` metabolic capability.
- **Why this limit:** The TauD dioxygenase releases taurine sulfur as sulfite while leaving its nitrogen on aminoacetaldehyde. This oxygen-dependent chemistry is kept apart from the sulfoacetaldehyde route, which uses different enzymes and nitrogen chemistry. Neither GIFT claims sulfide production, which needs further reduction.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `taurine_degradation_sulfoacetaldehyde` — Taurine to sulfite through sulfoacetaldehyde

- **Scope:** `TAURINE_IN` → `SULFITE`; `catabolic` metabolic capability.
- **Why this limit:** The nitrogen fate differs by route -- L-alanine from the transaminase, ammonium from the dehydrogenase -- so neither is a declared output and the GIFT makes no nitrogen claim. Acetyl phosphate is left internal rather than declared.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `taurine_uptake_abc` — Taurine uptake

- **Scope:** `TAURINE_EX` → `TAURINE_IN`; `transport` metabolic capability.
- **Why this limit:** TauABC has substrate-specific transporter markers, which license an explicit extracellular-to-cytoplasmic taurine boundary. Import is a separate encoded capability from either intracellular desulfonation route, so the two claims can compose without treating a catabolic enzyme as evidence of uptake.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

### `ammonium_assimilation` — Ammonium and 2-oxoglutarate to glutamate

- **Scope:** `AMMONIUM`, `OXOGLUTARATE` → `GLUTAMATE`; `anabolic` metabolic capability.
- **Why this limit:** A positive call is uninformative on its own, since 9482 of 10151 bacteria have it; the informative call is the negative one, which identifies genomes dependent on preformed amino acids. The capability exists in gifter so that ammonium is a boundary with a consumer rather than a terminal one.
- **Record:** curation record: [proposal-nitrogen-compound-catabolism.md](proposal-nitrogen-compound-catabolism.md).

## Curation proposal: aromatic compound degradation and mercury detoxification GIFTs

Primary reasoning record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `benzoate_degradation_catechol` — Benzoate to catechol

- **Scope:** `BENZOATE` → `CATECHOL`; `catabolic` metabolic capability.
- **Why this limit:** The markers are orthology groups for the substrate-determining subunits; the shared ferredoxin and ferredoxin reductase components of the same system are deliberately not required, because they are interchangeable between systems and are annotated two to three times less often than the subunits they serve, so requiring them would report an annotation gap as a missing capability.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `anthranilate_degradation_catechol` — Anthranilate to catechol

- **Scope:** `ANTHRANILATE` → `CATECHOL`; `catabolic` metabolic capability.
- **Why this limit:** The markers are orthology groups for the substrate-determining subunits; the shared ferredoxin and ferredoxin reductase components of the same system are deliberately not required, because they are interchangeable between systems and are annotated two to three times less often than the subunits they serve, so requiring them would report an annotation gap as a missing capability. Two alternative systems are curated, the antAB and andAcAd oxygenases, because they are non-homologous solutions annotated to different orthology groups.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `phenol_hydroxylation` — Phenol to catechol

- **Scope:** `PHENOL` → `CATECHOL`; `catabolic` metabolic capability.
- **Why this limit:** All six subunits of the dmp/pox/tom system are jointly required. Unlike the Rieske systems in this layer, these components are the enzyme rather than interchangeable electron carriers.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `catechol_ortho_cleavage` — Catechol to 3-oxoadipate by ortho cleavage

- **Scope:** `CATECHOL` → `OXOADIPATE`; `catabolic` metabolic capability.
- **Why this limit:** The lactone hydrolysis step carries two alternative systems, the standalone pcaD hydrolase and the fused pcaL protein that also decarboxylates.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `oxoadipate_activation` — 3-Oxoadipate to 3-oxoadipyl-CoA

- **Scope:** `OXOADIPATE` → `OXOADIPYL_COA`; `catabolic` metabolic capability.
- **Why this limit:** Curated as its own GIFT because 3-oxoadipyl-CoA is where the ortho-cleavage funnel and the aerobic phenylacetate route converge, and duplicating either segment inside the other would break composition through declared anchors.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `oxoadipyl_coa_thiolysis` — 3-Oxoadipyl-CoA to succinyl-CoA and acetyl-CoA

- **Scope:** `OXOADIPYL_COA` → `SUCCINYL_COA`, `ACETYL_COA`; `catabolic` metabolic capability.
- **Why this limit:** The thiolase orthologue is shared with the phenylacetate route, which is why it is curated once here rather than inside each upstream GIFT.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `catechol_meta_cleavage` — Catechol to 2-oxopent-4-enoate by meta cleavage

- **Scope:** `CATECHOL` → `OXOPENTENOATE`; `catabolic` metabolic capability.
- **Why this limit:** K07104 is deliberately refused as evidence of catechol 2,3-dioxygenase. It is assigned in 2081 KEGG genomes dominated by Bacillus, Streptococcus, Staphylococcus and Listeria, only 276 of which carry any lower meta pathway gene, and accepting it would put an over-broad marker in reach of every future GIFT that declares this activity. K00446 is used instead, corroborated by NCBIfam TIGR03211.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `oxopentenoate_degradation` — 2-Oxopent-4-enoate to pyruvate and acetyl-CoA

- **Scope:** `OXOPENTENOATE` → `PYRUVATE`, `ACETYL_COA`; `catabolic` metabolic capability.
- **Why this limit:** Curated once as an atomic GIFT rather than duplicated inside every upper route that ends here, which is what composition through declared anchors is for. Two alternative system sets are curated per step, the mhp and the bph/xyl/tes enzymes.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `phenylacetate_degradation` — Phenylacetate to 3-oxoadipyl-CoA

- **Scope:** `PHENYLACETATE` → `OXOADIPYL_COA`; `catabolic` metabolic capability.
- **Why this limit:** Ends at 3-oxoadipyl-CoA so that the terminal thiolysis is not duplicated: oxoadipyl_coa_thiolysis carries it once for this route and for the ortho-cleavage funnel alike. The route's last three steps use chain-generic beta-oxidation orthologues, one of which is already curated for butyrate formation; the specificity of the claim rests on paaK and the epoxidase, not on the tail.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `phenylpropanoate_dihydroxylation` — 3-Phenylpropanoate to 3-(2,3-dihydroxyphenyl)propanoate

- **Scope:** `PHENYLPROPANOATE` → `DHPP`; `catabolic` metabolic capability.
- **Why this limit:** The markers are orthology groups for the substrate-determining subunits; the shared ferredoxin and ferredoxin reductase components of the same system are deliberately not required, because they are interchangeable between systems and are annotated two to three times less often than the subunits they serve, so requiring them would report an annotation gap as a missing capability.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `hydroxyphenylpropanoate_hydroxylation` — 3-(3-Hydroxyphenyl)propanoate to 3-(2,3-dihydroxyphenyl)propanoate

- **Scope:** `HPP` → `DHPP`; `catabolic` metabolic capability.
- **Why this limit:** Curated separately from the dioxygenase entry because the substrates differ; KEGG module M00545 ORs the two into one module, which gifter cannot do, since a route must connect the GIFT's own declared boundaries.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `dihydroxyphenylpropanoate_degradation` — 3-(2,3-Dihydroxyphenyl)propanoate to 2-oxopent-4-enoate and succinate

- **Scope:** `DHPP` → `OXOPENTENOATE`, `SUCCINATE`; `catabolic` metabolic capability.
- **Why this limit:** Ends at 2-oxopent-4-enoate rather than at pyruvate and acetyl-CoA, so that the shared lower route is composed through the anchor instead of duplicated.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

### `mercury_detoxification` — Mercury detoxification

- **Scope:** Encodes the machinery that detoxifies mercury by reducing Hg(II) to volatile elemental Hg(0), through the NADPH-dependent mercuric reductase MerA, with delivery of the metal to the reductase, mercury-responsive induction of the operon and organomercurial carbon-mercury lysis as accessory functions. A positive call means the genome encodes MerA-dependent reduction. It does not mean the organism survives mercury exposure: that depends on the dose, on which mercury species it meets, and on efflux and sequestration systems this GIFT does not describe. (`defense` machinery capability.)
- **Why this limit:** Reduction is the only required function. A genome carrying merA alone detoxifies the Hg(II) that reaches its cytoplasm, which is the claim; requiring merT and merP would refuse such a genome on the strength of an operon architecture that varies, because merC and merE substitute for the pair in several lineages, and gifter has no evidence layer for how much metal gets in. Organomercurial lysis by MerB is curated as an accessory function and not as a second mechanism: broad-spectrum resistance is a genuinely different phenotype, and whether it deserves its own mechanism is recorded as an open question in inst/doc/proposal-aromatic-degradation.md. Mercury methylation by hgcAB is not this capability and is not curated: it makes mercury more toxic, not less.
- **Record:** curation record: [proposal-aromatic-degradation.md](proposal-aromatic-degradation.md).

## Curation proposal: the rest of amino acid metabolism

Primary reasoning record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `glutamine_biosynthesis` — L-glutamate and ammonium to L-glutamine

- **Scope:** `GLUTAMATE`, `AMMONIUM` → `GLUTAMINE`; `anabolic` metabolic capability.
- **Why this limit:** Glutamine is curated as its own capability rather than as part of ammonium assimilation because it is a required precursor elsewhere in the database -- pyrimidine, pyridoxal phosphate, tryptophan and histidine biosynthesis all consume its amide nitrogen -- and because a genome can carry glutamine synthetase without any glutamate synthase, in which case it amidates glutamate it cannot itself make.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `alanine_biosynthesis` — Pyruvate to L-alanine

- **Scope:** `PYRUVATE` → `ALANINE`; `anabolic` metabolic capability.
- **Why this limit:** KEGG has no module for alanine, and the textbook alanine transaminase orthology group K00814 is annotated in a single bacterial genome, so the trait is curated from the alanine-synthesising transaminases and alanine dehydrogenase instead. Only pyruvate is declared as a boundary: the two routes use different nitrogen donors, so declaring either would claim a requirement that half the routes do not have.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `aspartate_biosynthesis` — Oxaloacetate to L-aspartate

- **Scope:** `OXALOACETATE` → `ASPARTATE`; `anabolic` metabolic capability.
- **Why this limit:** One reaction, curated as a capability because it is the entry point of the entire aspartate family -- asparagine, the aspartate 4-semialdehyde trunk, lysine, threonine and methionine -- and because three curated GIFTs already declare L-aspartate as an input that nothing in the database produced.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `asparagine_biosynthesis` — L-aspartate to L-asparagine

- **Scope:** `ASPARTATE` → `ASPARAGINE`; `anabolic` metabolic capability.
- **Why this limit:** Only aspartate is declared as a boundary: the two routes differ in nitrogen source, and unlike the methionine pair -- where sulfide and cysteine are genuinely different nutritional situations -- ammonium and the glutamine amide are interchangeable intracellular nitrogen, so the difference does not justify two capabilities.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `dap_biosynthesis` — L-aspartate 4-semialdehyde to meso-diaminopimelate

- **Scope:** `ASA` → `MESO_DAP`; `anabolic` metabolic capability.
- **Why this limit:** KEGG draws these as four separate modules, each repeating the aspartate kinase and semialdehyde dehydrogenase steps that gifter curates separately, and each scoring badly alone -- 51.4, 5.6, 6.8 and 17.2 per cent of bacterial genomes. As alternative routes of one capability they cover 75.3 per cent, which is what the route layer exists to express. The capability ends at meso-diaminopimelate rather than at lysine because that molecule is also the peptidoglycan cross-link residue.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `lysine_biosynthesis_dap` — meso-diaminopimelate to L-lysine

- **Scope:** `MESO_DAP` → `LYSINE`; `anabolic` metabolic capability.
- **Why this limit:** Curated separately from the diaminopimelate branch because the two are separately informative: a genome can make the peptidoglycan precursor without making the amino acid, and LysA is present in 85.6 per cent of bacterial genomes while the branch that supplies it completes in 75.3 per cent.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `oxoisovalerate_biosynthesis` — Pyruvate to 3-methyl-2-oxobutanoate

- **Scope:** `PYRUVATE` → `OXOISOVALERATE`; `anabolic` metabolic capability.
- **Why this limit:** Cut here rather than at valine because the same three enzymes also serve the isoleucine branch on a different substrate, so the 2-oxo acid, not the amino acid, is what the evidence identifies -- and because pantothenate biosynthesis already declared this molecule as an input that nothing produced.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `valine_biosynthesis` — 3-methyl-2-oxobutanoate to L-valine

- **Scope:** `OXOISOVALERATE` → `VALINE`; `anabolic` metabolic capability.
- **Why this limit:** One reaction, curated as a capability because it is the step that establishes valine identity and because the branchpoint before it feeds pantothenate and leucine as well. The same aminotransferase serves leucine and isoleucine, so the marker fires for all three; what separates the three traits is the 2-oxo acid supply, and each of those is separately evidenced.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `leucine_biosynthesis` — 3-methyl-2-oxobutanoate to L-leucine

- **Scope:** `OXOISOVALERATE` → `LEUCINE`; `anabolic` metabolic capability.
- **Why this limit:** Extended past the module boundary, which stops at 2-oxoisocaproate, because the amino acid is the capability a reader is asking about and the transamination is the same enzyme already curated for valine.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `oxobutanoate_biosynthesis_citramalate` — Pyruvate to 2-oxobutanoate

- **Scope:** `PYRUVATE` → `OXOBUTANOATE`; `anabolic` metabolic capability.
- **Why this limit:** Rare -- 3.3 per cent of bacterial genomes -- and curated because it is the only isoleucine route available to a genome that cannot make threonine, which is exactly the case a composition graph should be able to answer.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `isoleucine_biosynthesis` — 2-oxobutanoate to L-isoleucine

- **Scope:** `OXOBUTANOATE` → `ISOLEUCINE`; `anabolic` metabolic capability.
- **Why this limit:** The four enzymes are the same ones that build valine from two pyruvates; the reactions are different because the substrate is. Cutting at 2-oxobutanoate is what makes the two amino acids separable, and it is also what connects isoleucine to its two suppliers: threonine deamination and the citramalate route.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `phenylalanine_biosynthesis` — Chorismate to L-phenylalanine

- **Scope:** `CHORISMATE` → `PHENYLALANINE`; `anabolic` metabolic capability.
- **Why this limit:** The final transamination is evidenced by a wider marker set than KEGG uses: requiring TyrB alone calls the trait in 2296 bacterial genomes where the discriminating aryl skeleton is present in 7796, and accepting the aspartate and branched-chain aminotransferases -- which do transaminate aromatic 2-oxo acids -- recovers 7733. The step is kept required because it is real chemistry, but the specificity of the claim rests on the skeleton, not on the transaminase.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `tyrosine_biosynthesis` — Chorismate to L-tyrosine

- **Scope:** `CHORISMATE` → `TYROSINE`; `anabolic` metabolic capability.
- **Why this limit:** The final transamination carries the same widened marker set as phenylalanine biosynthesis, for the same measured reason.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `tryptophan_biosynthesis` — Chorismate and L-glutamine to L-tryptophan

- **Scope:** `CHORISMATE`, `GLUTAMINE` → `TRYPTOPHAN`; `anabolic` metabolic capability.
- **Why this limit:** L-glutamine is declared as an input because the anthranilate synthase amidotransfer is the nitrogen source of the ring in every route, which is the same reading of an amidotransferase already applied to pyrimidine and pyridoxal phosphate biosynthesis; L-serine, which supplies the side chain, is not, because it is a co-substrate of the last step rather than the boundary the trait is about. The indole intermediate of tryptophan synthase is channelled between the two subunits and never released, so this GIFT does not connect to the indole anchor.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `histidine_biosynthesis` — PRPP and L-glutamine to L-histidine

- **Scope:** `PRPP`, `GLUTAMINE` → `HISTIDINE`; `anabolic` metabolic capability.
- **Why this limit:** The module boundary is kept unchanged because the pathway has no stable intermediate that another capability consumes, which is the test for a cut. L-glutamine is declared as an input for the imidazole glycerol-phosphate synthase amidotransfer; the AICAR released by the same reaction is not declared as an output, on the precedent of L-homocysteine, because it is an internal participant of purine core biosynthesis and an edge there would assert a composition nobody would read as biology.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `proline_biosynthesis` — L-glutamate to L-proline

- **Scope:** `GLUTAMATE` → `PROLINE`; `anabolic` metabolic capability.
- **Why this limit:** L-glutamate is declared as an input here, unlike in the transamination-dependent GIFTs of this layer, because its carbon skeleton becomes the product.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `ornithine_biosynthesis` — L-glutamate to L-ornithine

- **Scope:** `GLUTAMATE` → `ORNITHINE`; `anabolic` metabolic capability.
- **Why this limit:** The cyclic ArgJ route is the dominant one outside the Enterobacteriaceae, and the two are separately evidenced. The LysW-carrier route of Thermus and the archaea is not curated: its distinguishing orthology group is annotated in no bacterial genome.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `arginine_biosynthesis` — L-ornithine to L-arginine

- **Scope:** `ORNITHINE` → `ARGININE`; `anabolic` metabolic capability.
- **Why this limit:** L-citrulline stays internal: the arginine deiminase pathway passes through the same molecule in the opposite direction, and declaring it would assert a composition edge between a biosynthetic and a catabolic capability that share one reversible enzyme rather than a metabolite boundary.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `arginine_deiminase_pathway` — L-arginine to L-ornithine and ammonium

- **Scope:** `ARGININE` → `ORNITHINE`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** The trait most users mean by arginine catabolism, and the principal acid-resistance and ATP-generating strategy of streptococci, lactobacilli and many oral and vaginal taxa. All three components are required: ornithine carbamoyltransferase alone is shared with arginine biosynthesis running the other way, so it is the deiminase and the carbamate kinase that identify the catabolic pathway. L-citrulline stays internal, which is why this GIFT and arginine biosynthesis share no boundary except the two amino acids themselves.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `histidine_degradation_glutamate` — L-histidine to L-glutamate and ammonium

- **Scope:** `HISTIDINE` → `GLUTAMATE`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** Curated with the formamide-releasing hydrolase rather than the folate-dependent formiminotransferase, because the transferase route ends in the one-carbon pool, which gifter has no anchors for.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `threonine_deamination` — L-threonine to 2-oxobutanoate and ammonium

- **Scope:** `THREONINE` → `OXOBUTANOATE`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** The chemistry is catabolic wherever it runs, and the same enzyme serves the first step of isoleucine biosynthesis: curating it once, as catabolism, and letting isoleucine biosynthesis compose from the 2-oxobutanoate anchor is what keeps one reaction in one GIFT. The resulting threonine-to-isoleucine chain crosses modes, which is the case the composition rule anticipates.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `serine_deamination` — L-serine to pyruvate and ammonium

- **Scope:** `SERINE` → `PYRUVATE`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** K01752 is excluded because KEGG assigns it to complete single-chain proteins and to either isolated subunit of the split enzyme.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md); curation record: [assessment-serine-deamination-revision.md](assessment-serine-deamination-revision.md); analysis script: [serine_deamination_marker_audit.py](../../data-raw/serine_deamination_marker_audit.py); result table: [serine-deamination-gene-audit.tsv](../../data-raw/reference/serine-deamination-gene-audit.tsv); result table: [serine-deamination-genome-audit.tsv](../../data-raw/reference/serine-deamination-genome-audit.tsv).

### `glutamate_decarboxylation_gaba` — L-glutamate to 4-aminobutanoate

- **Scope:** `GLUTAMATE` → `GABA`; `catabolic` metabolic capability.
- **Why this limit:** The reaction consumes a cytoplasmic proton, which is why it is the core of glutamate-dependent acid resistance; the product is also the most studied microbially produced neuroactive compound. gifter claims the encoded decarboxylation only: the antiporter that makes the system work as acid resistance is transport chemistry this layer does not curate, and no evidence layer here says whether GABA leaves the cell.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `tryptophan_degradation_indole` — L-tryptophan to indole, pyruvate and ammonium

- **Scope:** `TRYPTOPHAN` → `INDOLE`, `PYRUVATE`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** One reaction, one orthology group, and the strongest host-signal claim in the amino acid layer: bacterial indole is an aryl hydrocarbon receptor ligand that modulates epithelial barrier function, and the reaction is what the classical clinical indole test detects. Curated as a capability on the same grounds as cytidylate biosynthesis: a single transformation that establishes a product identity nothing else in the database produces.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `methionine_degradation_methanethiol` — L-methionine to methanethiol and 2-oxobutanoate

- **Scope:** `METHIONINE` → `METHANETHIOL`, `OXOBUTANOATE`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** Methanethiol is a principal volatile sulfur compound of oral malodour and a documented colonocyte irritant. The enzyme is promiscuous towards homocysteine and cysteine; the GIFT is named for methionine and its marker is deliberately not accepted as evidence for any cysteine capability.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `cysteine_degradation_sulfide` — L-cysteine to hydrogen sulfide and pyruvate

- **Scope:** `CYSTEINE` → `SULFIDE`, `PYRUVATE`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** The trait is knowingly under-called: many PLP enzymes carry this activity as a side reaction, and accepting them would make every transsulfuration genome a sulfide producer, since cystathionine beta-lyase is already curated as evidence for cysteine biosynthesis. Only the dedicated desulfidase orthology groups are accepted, which is a claim about specificity rather than about prevalence. The product closes the sulfide anchor, which two biosynthesis GIFTs consumed and nothing produced.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `glycine_reduction_stickland` — Glycine to acetyl phosphate and ammonium

- **Scope:** `GLYCINE` → `ACETYL_PHOSPHATE`, `AMMONIUM`; `catabolic` metabolic capability.
- **Why this limit:** The complete selenoprotein complex is required, which is what makes the trait specific -- 128 of 10151 bacterial genomes -- and it is diagnostic of proteolytic Clostridia including Clostridioides difficile. gifter states the encoded chemistry only: selenocysteine incorporation itself is a separate capability this layer does not evaluate.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

### `proline_reduction_stickland` — L-proline to 5-aminopentanoate

- **Scope:** `PROLINE` → `AMINOPENTANOATE`; `catabolic` metabolic capability.
- **Why this limit:** The racemase is required because the reductase is specific for the D isomer, and the two together are what distinguishes the trait from proline oxidation. Rare and diagnostic, like glycine reduction, and it forms a cross-mode pair with proline biosynthesis.
- **Record:** curation record: [proposal-amino-acid-metabolism.md](proposal-amino-acid-metabolism.md).

## Curation proposal: next coherent GIFT release

Primary reasoning record: [proposal-next-gift-release.md](proposal-next-gift-release.md).

### `glyoxylate_bypass` — Isocitrate and acetyl-CoA to succinate and malate

- **Scope:** `ISOCITRATE`, `ACETYL_COA` → `SUCCINATE`, `MALATE`; `catabolic` metabolic capability.
- **Why this limit:** Isocitrate is the branch boundary; glyoxylate is produced and consumed inside the complete route and remains internal. K01639 is refused because it is N-acetylneuraminate lyase, not malate synthase. K19282 is deferred because its malyl-CoA route requires two different Rhea reactions rather than the direct malate-synthase reaction curated here.
- **Record:** curation record: [proposal-next-gift-release.md](proposal-next-gift-release.md).

### `nitrogen_fixation` — Dinitrogen to ammonium

- **Scope:** `NITROGEN` → `AMMONIUM`; `anabolic` metabolic capability.
- **Why this limit:** The molybdenum architecture requires NifHDK, NifEN and NifB; NifU, NifS, NifV and NifM are not required because their roles are not universally nitrogenase-specific or can be supplied by host pathways. A vanadium architecture requires VnfHDGK, VnfEN and NifB and is a separate route with its own Rhea master. NifH alone is explicitly insufficient. The Fe-only architecture is deferred because current KO groups do not separate AnfHDK from NifHDK while the minimum native assembly requirement remains context-dependent.
- **Record:** curation record: [proposal-next-gift-release.md](proposal-next-gift-release.md).

### `assimilatory_sulfate_reduction` — Sulfate to hydrogen sulfide

- **Scope:** `SULFATE` → `SULFIDE`; `anabolic` metabolic capability.
- **Why this limit:** Four minimal routes materialise the APS/PAPS and NADPH/ferredoxin alternatives. The shared CysH KO K00390 is refused because KEGG assigns it both EC 1.8.4.8 and 1.8.4.10 and it cannot decide which branch is complete; the two branch reactions therefore use reaction-specific EC markers. Dissimilatory AprAB and DsrAB markers are not accepted. CysNC is represented at the correct system layer as a fusion that can satisfy APS kinase and, with CysD, sulfate adenylyltransferase.
- **Record:** curation record: [proposal-next-gift-release.md](proposal-next-gift-release.md).

## Compatible solutes, heme, enterobactin and detoxification

Primary reasoning record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### `ectoine_biosynthesis` — Aspartate semialdehyde to ectoine

- **Scope:** `ASA` → `ECTOINE`; `anabolic` metabolic capability.
- **Why this limit:** Starts at the existing ASA branchpoint, so the aspartate kinase and semialdehyde dehydrogenase upstream of MetaCyc P101-PWY and KEGG M00033 are not duplicated. EctD, regulation and transport are excluded.
- **Record:** curation record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### `heme_b_biosynthesis` — Uroporphyrinogen III to heme b

- **Scope:** `UROGEN_III` → `HEME_B`; `anabolic` metabolic capability.
- **Why this limit:** Seven minimal routes materialise HemF/HemN and HemY/HemG/HemJ combinations plus the coproporphyrin HemY-HemH-HemQ route. The siroheme route has a different input boundary and is deliberately not folded into this GIFT.
- **Record:** curation record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### `dihydroxybenzoate_biosynthesis` — Chorismate to 2,3-dihydroxybenzoate

- **Scope:** `CHORISMATE` → `DIHYDROXYBENZOATE_2_3`; `anabolic` metabolic capability.
- **Why this limit:** The isochorismate reaction and its existing systems are reused. EntB supplies the lyase step and is also the aryl carrier in the downstream enterobactin GIFT; those functions remain separate components.
- **Record:** curation record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### `enterobactin_biosynthesis` — 2,3-Dihydroxybenzoate and serine to enterobactin

- **Scope:** `DIHYDROXYBENZOATE_2_3`, `SERINE` → `ENTEROBACTIN`; `anabolic` metabolic capability.
- **Why this limit:** The four proteins are jointly required components of one aggregate Rhea reaction system. The split at 2,3-dihydroxybenzoate lets the chorismate-derived head compose with other catecholate products without duplicating it.
- **Record:** curation record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### `methylglyoxal_detoxification` — Glutathione-dependent methylglyoxal detoxification

- **Scope:** Encodes the two-enzyme glutathione-dependent conversion of methylglyoxal to D-lactate by glyoxalases I and II. A positive call means this complete detoxifying mechanism is encoded. It does not mean methylglyoxal is present, the enzymes are active, or the organism survives or resists methylglyoxal exposure. (`defense` machinery capability.)
- **Why this limit:** The mechanism stops once the electrophile has been converted and glutathione regenerated. D-lactate oxidation is downstream metabolism; broad reductases, dehydrogenases and glyoxalase-III families are refused because their markers do not identify methylglyoxal at this specificity.
- **Record:** curation record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### `superoxide_detoxification` — Complete superoxide detoxification

- **Scope:** Encodes removal of superoxide followed by removal of the hydrogen peroxide produced, using one accepted system for each required function. A positive call means a complete two-stage chemical-detoxification mechanism is encoded. It does not mean reactive oxygen species are present, the machinery is expressed, or the organism withstands oxidative stress. (`defense` machinery capability.)
- **Why this limit:** SOD alone is incomplete because its product is hydrogen peroxide. Nickel SOD is refused without evidence for its required maturation protease, and superoxide reductase is deferred until its electron-delivery architecture is markable.
- **Record:** curation record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### `choline_to_betaine` — Choline to glycine betaine

- **Scope:** `CHOLINE` → `BETAINE`; `anabolic` metabolic capability.
- **Why this limit:** The output reuses the existing BETAINE anchor and composes with betaine demethylation. K14085 is refused because its broad ALDH7A1 annotation cannot identify betaine aldehyde; K00130 is accepted because the orthology group is explicitly betaine-aldehyde dehydrogenase.
- **Record:** curation record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

### `siroheme_biosynthesis` — Uroporphyrinogen III to siroheme

- **Scope:** `UROGEN_III` → `SIROHEME`; `anabolic` metabolic capability.
- **Why this limit:** The route uses three Rhea masters because RHEA:32459 consolidates the two sequential methyl transfers that MetaCyc records separately. CysG can satisfy all three reactions; Met8 satisfies dehydrogenation and ferrochelation; SirC plus SirB supplies the split terminal pair. Broad CbiX-family markers are refused where they cannot distinguish iron from cobalt or nickel insertion, so archaeal siroheme synthesis is knowingly under-called.
- **Record:** curation record: [proposal-compatible-solutes-heme-enterobactin-detoxification.md](proposal-compatible-solutes-heme-enterobactin-detoxification.md).

## Fates of anchors that had only one declared role

Primary reasoning record: [proposal-anchor-fates.md](proposal-anchor-fates.md).

### `ectoine_degradation` — L-ectoine to L-2,4-diaminobutanoate

- **Scope:** `ECTOINE` → `DABA`; `catabolic` metabolic capability.
- **Why this limit:** Cut at L-2,4-diaminobutanoate rather than at L-aspartate 4-semialdehyde or L-aspartate on purpose. Adding the DoeD step would mean attaching a second enzyme system to RHEA:11160, which ectoine_biosynthesis also uses, and K15785 was refused as an EctB alternative when that GIFT was curated. Evidence attaches to reactions rather than to routes, so admitting DoeD there would silently reverse that refusal.
- **Record:** curation record: [proposal-anchor-fates.md](proposal-anchor-fates.md).

### `hydroxyectoine_biosynthesis` — L-ectoine to 5-hydroxyectoine

- **Scope:** `ECTOINE` → `HYDROXYECTOINE`; `anabolic` metabolic capability.
- **Why this limit:** Curated separately from ectoine_biosynthesis because the product is a distinct compatible solute rather than a modified intermediate, and because only some ectoine producers encode the hydroxylase. A positive call names the encoded product and makes no osmotic- or thermotolerance claim.
- **Record:** curation record: [proposal-anchor-fates.md](proposal-anchor-fates.md).

### `lactate_formation_lactaldehyde` — (S)-lactaldehyde to (S)-lactate

- **Scope:** `LACTALDEHYDE` → `LACTATE_L`; `catabolic` metabolic capability.
- **Why this limit:** The lactaldehyde branchpoint now has two curated fates, reduction to propane-1,2-diol and oxidation to lactate, which is what makes it worth being an anchor.
- **Record:** curation record: [proposal-anchor-fates.md](proposal-anchor-fates.md).

## Assessment: NCBIfam as a marker namespace, read against the deferral register

Primary reasoning record: [proposal-ncbifam-namespace.md](proposal-ncbifam-namespace.md).

### `siroheme_to_heme_b` — Siroheme to heme b

- **Scope:** `SIROHEME` → `HEME_B`; `anabolic` metabolic capability.
- **Why this limit:** The first capability in gifter that depends on the NCBIFAM namespace. Its refusal in database 2026.20.3 named exactly this retrigger: AhbA and AhbB are jointly required and KEGG assigns both to K22225, so the heterodimer could not be evidenced. NF040708.3 and NF040707.3 separate them and K22225 is admitted nowhere. Two minimal routes differ only in the terminal step, AhbD or the peroxide-dependent HemQ that heme_b_biosynthesis already curates.
- **Record:** curation record: [proposal-ncbifam-namespace.md](proposal-ncbifam-namespace.md).

## Regulatory and defense GIFT expansion: October 2026 assessment

Primary reasoning record: [proposal-regulatory-defense-expansion.md](proposal-regulatory-defense-expansion.md).

### `serine_chemoreception` — Serine chemoreception

- **Scope:** Encodes a Tsr-family L-serine-responsive chemoreceptor connected to the CheA-CheW, CheY and CheR-CheB chemotaxis circuit. A positive call means this signalling machinery is encoded. It does not mean the cell swims toward serine or senses no other ligand. (`regulatory` machinery capability.)
- **Why this limit:** The receptor requires the Tsr-specific NCBIfam equivalog NF011615.0; the broad KO K05874 is deliberately not accepted for the ligand-specific reception function. The downstream functions are shared with the existing chemotaxis circuits. See inst/doc/proposal-regulatory-defense-expansion.md.
- **Record:** curation record: [proposal-regulatory-defense-expansion.md](proposal-regulatory-defense-expansion.md); curation record: [proposal-ncbifam-namespace.md](proposal-ncbifam-namespace.md).

## Curation proposal: antimicrobial detoxification, and CARD as a gifter source

Primary reasoning record: [proposal-antimicrobial-detoxification.md](proposal-antimicrobial-detoxification.md).

### `beta_lactam_detoxification` — Beta-lactam detoxification

- **Scope:** Encodes a beta-lactamase that hydrolyses the beta-lactam ring of at least one beta-lactam antibiotic. A positive call means the catalytic machinery is encoded; it does not establish which drug is hydrolysed, expression, localisation, or resistance to treatment. (`defense` machinery capability.)
- **Why this limit:** One required hydrolysis function has four alternative Ambler-class systems. The 66 accepted KOs are enzyme-specific EC 3.5.2.6 groups, not the broader metallo-beta-lactamase fold. RHEA:20401 records the class-level chemistry. See inst/doc/proposal-antimicrobial-detoxification.md and inst/doc/proposal-regulatory-defense-expansion.md.
- **Record:** curation record: [proposal-antimicrobial-detoxification.md](proposal-antimicrobial-detoxification.md); curation record: [proposal-regulatory-defense-expansion.md](proposal-regulatory-defense-expansion.md); analysis script: [marker_specificity_screen.R](../../data-raw/marker_specificity_screen.R); result table: [ko-reaction-specificity.tsv](../../data-raw/reference/ko-reaction-specificity.tsv).

### `chloramphenicol_detoxification` — Chloramphenicol detoxification

- **Scope:** Encodes a chloramphenicol O-acetyltransferase that converts chloramphenicol to chloramphenicol 3-acetate using acetyl-CoA. A positive call means the catalytic machinery is encoded. It does not mean the organism withstands chloramphenicol exposure. (`defense` machinery capability.)
- **Why this limit:** Type A and type B chloramphenicol acetyltransferases are alternative systems of the same RHEA:18421 chemistry. The type B KO is accepted only while its EC assignment remains specific to chloramphenicol. See inst/doc/proposal-antimicrobial-detoxification.md.
- **Record:** curation record: [proposal-antimicrobial-detoxification.md](proposal-antimicrobial-detoxification.md); curation record: [proposal-regulatory-defense-expansion.md](proposal-regulatory-defense-expansion.md); analysis script: [marker_specificity_screen.R](../../data-raw/marker_specificity_screen.R); result table: [ko-reaction-specificity.tsv](../../data-raw/reference/ko-reaction-specificity.tsv).
